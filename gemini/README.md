# Gemini Query Tool

A simple CLI tool to query the Gemini API from the command line.

## Prerequisites

- Go installed
- A Gemini API key set as an environment variable (`GEMINI_API_KEY`)

## Usage

### Ask a question

```
cli/query "Your question here"
```

Example:

```
cli/query "Briefly explain how AI inference works"
```

### List available models

```
cli/query list
```

This will print all models available to your API key.

## Notes

- The tool uses `gemini-2.5-flash` by default.
- Multi-word questions must be wrapped in quotes.
- Free tier users have rate and daily request limits depending on the model.


### Examples

```
 ./query list | head -n 5

models/gemini-2.5-flash
models/gemini-2.5-pro
models/gemini-2.0-flash
models/gemini-2.0-flash-001
models/gemini-2.0-flash-exp-image-generation
```

```
 ./query "Briefly explain how AI inference works"

Asking Gemini: Briefly explain how AI inference works
AI inference is the process where a **trained** AI model uses **new, unseen data** to make a **prediction, classification, or decision.**

Here's the breakdown:

1.  **Input:** You feed the trained model new data (e.g., an image, a piece of text, numerical values).
2.  **Processing:** The model, using the patterns and relationships it **learned during its training phase** (represented by its internal parameters like weights and biases), performs a series of mathematical computations on this input.
3.  **Output:** These computations process the input through the model's structure (e.g., layers of a neural network) to generate a specific output, such as identifying an object in the image, translating text, predicting a stock price, or generating new content.

Essentially, it's the "applying knowledge" phase after the "learning" phase.
```