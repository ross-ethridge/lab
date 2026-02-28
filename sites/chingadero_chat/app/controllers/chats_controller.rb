class ChatsController < ApplicationController
  def index
    # Load the whole conversation to display on the screen
    @messages = Message.order(:created_at)
  end

  def create
    user_content = params[:content]
    return redirect_to chats_path if user_content.blank?

    # 1. Save the user's prompt
    Message.create!(role: 'user', content: user_content)

    # 2. Fetch the updated conversation history
    history = Message.order(:created_at).to_a

    # 3. Pass history to Gemini API (our service object)
    ai_response = GeminiService.new.call(history)

    # 4. Save Gemini's response
    Message.create!(role: 'model', content: ai_response)

    # Reload the page to show the new messages
    redirect_to chats_path
  end
end