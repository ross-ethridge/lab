# app/services/gemini_service.rb
require 'net/http'
require 'uri'
require 'json'

class GeminiService
  # We are using Gemini 1.5 Flash as it is fast and heavily recommended by Google
  API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent".freeze

  def call(messages)
    uri = URI("#{API_URL}?key=#{ENV['GEMINI_API_KEY']}")
    
    # Format the database messages into the JSON schema Google Studio expects
    formatted_contents = messages.map do |msg|
      {
        role: msg.role, # 'user' or 'model'
        parts:[{ text: msg.content }]
      }
    end

    # Build the HTTP POST request
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = { contents: formatted_contents }.to_json

    # Execute the request
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    result = JSON.parse(response.body)
    
    # Return the text response or surface an error
    if response.is_a?(Net::HTTPSuccess)
      result.dig("candidates", 0, "content", "parts", 0, "text")
    else
      "Error: #{result.dig('error', 'message') || 'Unknown API error'}"
    end
  end
end
