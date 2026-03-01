# Telegram Bot Template

A Telegram bot template built with Lua, featuring AI chat, media handling, and inline keyboards.

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Author](#author)

## Overview

A Telegram bot template using Lua with async support via Copas. Features AI chat powered by OpenRouter, conversation history stored in Supabase, media file ID logging, and inline keyboard support.

## Getting Started

### Prerequisites

- Lua 5.4
- LuaRocks
- curl (for HTTP requests)

### Installation
```bash
luarocks install copas
luarocks install telegram-bot-lua
luarocks install dkjson
luarocks install luasocket
luarocks install luasec
```

### Configuration

Create a `.env` file in the root directory:
```
BOT_TOKEN=your_telegram_bot_token
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SECRET_KEY=your_supabase_secret_key
OPENROUTER_API_KEY=your_openrouter_api_key
```

### Supabase Setup

Create a `chat_history` table in your Supabase project:
```sql
CREATE TABLE chat_history (
    id bigserial PRIMARY KEY,
    user_id bigint NOT NULL,
    role text NOT NULL,
    content text NOT NULL,
    created_at timestamp DEFAULT now()
);
```

### Run
```bash
lua bot.lua
```

## Usage

| Command | Description |
|---------|-------------|
| `/start` | Check bot status |
| `/help` | Show available commands |
| `/ping` | Test response |
| `/ask <message>` | Chat with AI |

## Project Structure
```
.
├── bot.lua       # Main bot logic
├── media.lua     # Media handling and helpers
└── .env          # Environment variables (not committed)
```

## Author

- GitHub - [@ManhattannC](https://github.com/ManhattannC)