# Telegram Bot Template

A simple Telegram bot template built with Lua.

## Table of contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Author](#author)

## Overview

A minimal Telegram bot template using Lua with async support via Copas. Built to be extended with custom commands and logic.

## Getting Started

### Prerequisites

- Lua
- LuaRocks
- `copas` library
- `telegram-bot-lua` library

### Installation
```bash
luarocks install copas
luarocks install telegram-bot-lua
```

### Configuration

Create a `.env` file in the root directory:
```
BOT_TOKEN=your_token_here
```

### Run
```bash
lua bot.lua
```

## Usage

| Command | Description |
|---------|-------------|
| `/start` | Start the bot |

## Author

- GitHub - [@Manhattann](https://github.com/ManhattannC)
