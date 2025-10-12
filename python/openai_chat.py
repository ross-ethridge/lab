#!/usr/bin/env python3
"""
chatgpt_demo.py

A minimal example that sends a user prompt to OpenAI's ChatCompletion API
and prints the response.  It demonstrates:
  • Setting the API key from an environment variable
  • A simple message format
  • Basic error handling
"""

import os
import sys
from openai import OpenAI
from typing import Optional

# ----------------------------------------------------------------------
# 1️⃣  Load your API key from the environment
# ----------------------------------------------------------------------
API_KEY = os.getenv("OPENAI_API_KEY")
if not API_KEY:
    print("❌ ERROR: OPENAI_API_KEY environment variable not set.")
    print("   You can set it with:")
    print("       export OPENAI_API_KEY='sk-…'   # Linux/macOS")
    print("       setx OPENAI_API_KEY 'sk-…'    # Windows")
    sys.exit(1)

client = OpenAI(api_key=API_KEY)
# ----------------------------------------------------------------------
# 2️⃣  Helper: ask a question and get a response
# ----------------------------------------------------------------------
def ask_chatgpt(
    prompt: str,
    model: str = "gpt-4o-mini",      # choose the model you want
    temperature: float = 0.7,
    max_tokens: int = 512,
    *,
    stream: bool = True,
    ) -> Optional[str]:
    """
    Sends a prompt to the OpenAI ChatCompletion endpoint and returns the reply.

    Parameters
    ----------
    prompt : str
        The user message you want the model to respond to.
    model : str
        The model id.  "gpt-4o-mini" is cheap & fast; change if you want a different one.
    temperature : float
        Controls randomness.  0.0 = deterministic, 1.0 = more creative.
    max_tokens : int
        The maximum number of tokens in the model’s reply.
    stream : bool
        If True, prints tokens as they arrive (streaming mode).

    Returns
    -------
    Optional[str]
        The full reply text, or None if an error occurred.
    """
    try:
        if stream:
            # Streaming mode – print each token as it arrives
            response = client.chat.completions.create(model=model,
            messages=[{"role": "user", "content": prompt}],
            temperature=temperature,
            max_tokens=max_tokens,
            stream=True)
            reply = ""
            for chunk in response:
                delta = chunk.choices[0].delta
                if "content" in delta:
                    token = delta["content"]
                    print(token, end="", flush=True)
                    reply += token
            print()  # newline after stream ends
            return reply

        else:
            # Normal completion (single request)
            completion = client.chat.completions.create(model=model,
            messages=[{"role": "user", "content": prompt}],
            temperature=temperature,
            max_tokens=max_tokens)
            return completion.choices[0].message.content

    except openai.OpenAIError as exc:
        # openai.OpenAIError is the base class for all API errors
        print(f"\n❌ API error: {exc}")
        return None
    except Exception as exc:
        # Catch-all for unforeseen errors
        print(f"\n❌ Unexpected error: {exc}")
        return None


# ----------------------------------------------------------------------
# 3️⃣  Demo: prompt the user, get a reply, and print it
# ----------------------------------------------------------------------
def main() -> None:
    print("Welcome to the OpenAI ChatCompletion demo!")
    print("Type your question and hit Enter.  Type 'exit' to quit.\n")

    while True:
        user_input = input("You: ").strip()
        if user_input.lower() in {"exit", "quit"}:
            print("Bye!")
            break
        if not user_input:
            continue

        print("\n🤖 Thinking…")
        reply = ask_chatgpt(user_input, stream=False)
        if reply is not None:
            print(f"\nOpenAI: {reply}\n")
        else:
            print("❌ Failed to get a response.\n")


if __name__ == "__main__":
    main()
