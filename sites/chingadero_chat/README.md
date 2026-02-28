# Chingadero Chat

A Rails chat app that talks to Google Gemini. Type a message, get a response. The full conversation history is sent with each request so Gemini has context.

## Stack

- Ruby on Rails 8.1
- PostgreSQL
- Google Gemini 2.5 Flash API
- Solid Cable (Action Cable backend)
- Docker / Docker Compose

## Requirements

- Docker and Docker Compose
- A [Google AI Studio](https://aistudio.google.com/) API key

## Setup

**1. Create a `.env` file:**

```
GEMINI_API_KEY=your_api_key_here
POSTGRES_USER=chingadero_chat
POSTGRES_PASSWORD=your_password_here
SECRET_KEY_BASE=your_secret_key_base_here
```

Generate a secret key base with:
```
openssl rand -hex 64
```

**2. Build and create the databases:**

```
docker compose -f docker-compose.prod.yaml build web
docker compose -f docker-compose.prod.yaml run --rm web bin/rails db:prepare
```

**3. Start the app:**

```
docker compose -f docker-compose.prod.yaml up -d
```

The app runs on `http://localhost`.
