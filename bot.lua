#!/usr/bin/env lua

local copas = require('copas')
local telegram = require('telegram-bot-lua')
local json = require("dkjson")
local media = require("media")

-- Load Env
local function load_env()
    local env = {}
    local function clean_val(v)
        if type(v) ~= "string" then return v end
        return v:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^['\"]", ""):gsub("['\"]$", "")
    end
    env.bot_token = clean_val(os.getenv("BOT_TOKEN"))
    env.supabase_url = clean_val(os.getenv("SUPABASE_URL"))
    env.supabase_secret_key = clean_val(os.getenv("SUPABASE_SECRET_KEY"))
    env.openrouter_api_key = clean_val(os.getenv("OPENROUTER_API_KEY"))

    -- token loader
    local f = io.open(".env", "r")
    if f then
        for line in f:lines() do
            local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
            if key and value then
                value = clean_val(value)
                if key == "BOT_TOKEN" and not env.bot_token then env.bot_token = value end
                if key == "SUPABASE_URL" and not env.supabase_url then env.supabase_url = value end
                if key == "SUPABASE_SECRET_KEY" and not env.supabase_secret_key then env.supabase_secret_key = value end
                if key == "OPENROUTER_API_KEY" and not env.openrouter_api_key then env.openrouter_api_key = value end
            end
        end
        f:close()
    end
    return env
end

local function log(msg)
    print(string.format("[%s] %s", os.date("%Y-%m-%d %H:%M:%S"), msg))
end

local env = load_env()

if not env.bot_token or not env.supabase_url or not env.supabase_secret_key or not env.openrouter_api_key then
    print("Missing environment variables!")
    os.exit(1)
end

local bot = telegram.configure(env.bot_token)
print("Bot configured, starting...")

-- HTTP Request using curl
local function http_request(url, method, headers, body)
    method = method or "GET"

    local cmd = string.format('curl -s -w "\\n%%{http_code}" --max-time 30 --connect-timeout 10 -X %s "%s"', method, url)

    if headers then
        for k, v in pairs(headers) do
            cmd = cmd .. string.format(' -H "%s: %s"', k, v)
        end
    end

    if body and (method == "POST" or method == "PUT") then
        local escaped = body:gsub("'", "'\\''")
        cmd = cmd .. ' -d \'' .. escaped .. '\''
    end

    local handle = io.popen(cmd, "r")
    if not handle then
        return nil, 500, "Failed to execute curl"
    end

    local output = handle:read("*a")
    handle:close()

    -- Parse status code
    local status_code = tonumber(output:match("(%d+)%s*$")) or 500
    local result = output:gsub("%d+%s*$", ""):gsub("\n%s*$", "")

    if status_code >= 400 then
        log("HTTP " .. status_code .. ": " .. result:sub(1, 200))
        return nil, status_code, "HTTP " .. status_code
    end

    -- Try parse JSON
    if result:match("^%s*[{%[]") then
        local decoded, _, err = json.decode(result)
        return decoded or {}, status_code, err
    end

    return result, status_code, nil
end

-- Supabase Helpers
local function supabase_get_history(user_id)
    local url = env.supabase_url .. "/rest/v1/chat_history?user_id=eq." .. user_id .. "&order=created_at.asc&limit=20"
    local headers = {
        ["apikey"] = env.supabase_secret_key,
        ["Authorization"] = "Bearer " .. env.supabase_secret_key,
        ["Content-Type"] = "application/json"
    }
    local result, _, err = http_request(url, "GET", headers)
    if not result then
        log("Supabase error: " .. tostring(err))
        return {}
    end
    return result
end

local function supabase_save_message(user_id, role, content)
    local url = env.supabase_url .. "/rest/v1/chat_history"
    local headers = {
        ["apikey"] = env.supabase_secret_key,
        ["Authorization"] = "Bearer " .. env.supabase_secret_key,
        ["Content-Type"] = "application/json"
    }
    local body = json.encode({ user_id = user_id, role = role, content = content })
    http_request(url, "POST", headers, body) -- fire & forget
end

-- OpenRouter AI
local function ask_ai(user_id, user_message)
    local history = supabase_get_history(user_id)
    local messages = { { role = "system", content = "You are a chill and casual assistant. Keep responses short and natural, like texting a friend. No formal greetings, no unnecessary filler. Adapt to the user's language and vibe." } }

    for _, row in ipairs(history) do
        table.insert(messages, { role = row.role, content = row.content })
    end
    table.insert(messages, { role = "user", content = user_message })

    local url = "https://openrouter.ai/api/v1/chat/completions"
    local headers = {
        ["Authorization"] = "Bearer " .. env.openrouter_api_key,
        ["Content-Type"] = "application/json",
        ["HTTP-Referer"] = "https://github.com/yourusername/yourbot",
        ["X-Title"] = "Telegram AI Bot"
    }
    local body = json.encode({
        model = "openrouter/free",
        messages = messages,
        max_tokens = 1000
    })

    log("Asking OpenRouter...")
    local result, status, err = http_request(url, "POST", headers, body)

    if not result then
        log("OpenRouter failed: " .. tostring(err or status))
        return nil
    end

    if status ~= 200 then
        log("OpenRouter HTTP " .. status)
        return nil
    end

    local reply = result.choices and result.choices[1] and result.choices[1].message.content
    if not reply then
        log("OpenRouter: no reply")
        return nil
    end

    log("Got reply (" .. #reply .. " chars)")

    -- Save to DB async
    copas.addthread(function()
        supabase_save_message(user_id, "user", user_message)
        supabase_save_message(user_id, "assistant", reply)
    end)

    return reply
end

-- Command Handlers
local commands = {}

function commands.start(chat_id)
    bot.send_message(chat_id, "Bot online! Use /help")
end

function commands.help(chat_id)
    local kb = {
        { { text = "/start", callback_data = "/start" }, { text = "/ping", callback_data = "/ping" } },
        { { text = "/help", callback_data = "/help" } }
    }
    bot.send_message(chat_id, "Commands:\n/start\n/ping\n/ask <msg>", {
        parse_mode = "Markdown",
        reply_markup = { inline_keyboard = kb }
    })
end

function commands.ping(chat_id)
    bot.send_message(chat_id, "Pong!")
end

function commands.ask(chat_id, args, user_id)
    if not args or args == "" then
        bot.send_message(chat_id, "Contoh: `/ask halo`")
        return
    end
    bot.send_chat_action(chat_id, "typing")

    copas.addthread(function()
        local reply = ask_ai(user_id, args)
        bot.send_message(chat_id, reply or "Maybe dead, try again later")
    end)
end

local function unknown_command(chat_id, cmd)
    bot.send_message(chat_id, "Unknown: /" .. cmd .. "\nUse /help")
end

local function process_command(text, chat_id, user_id)
    local cmd, args = text:match("^/(%w+)@?%S*%s*(.*)")
    if not cmd then return end
    local handler = commands[cmd:lower()]
    if handler then
        local ok, err = pcall(handler, chat_id, args, user_id)
        if not ok then
            log("Error /" .. cmd .. ": " .. tostring(err))
            bot.send_message(chat_id, "Command error")
        end
    else
        unknown_command(chat_id, cmd)
    end
end

-- Message Handler
function bot.on_message(message)
    if not message then return end
    media.log_media(message, log)
    if not message.text then return end

    local text, chat_id, user_id = message.text, message.chat.id, message.from.id
    local username = message.from.username or "Unknown"
    log(string.format(">>> [%s] %s: %s", chat_id, username, text))
    if text:sub(1, 1) == "/" then
        process_command(text, chat_id, user_id)
    end
end

-- Callback Handler
function bot.on_callback_query(cb)
    bot.answer_callback_query(cb.id)
    bot.delete_message(cb.message.chat.id, cb.message.message_id)
    if cb.data:sub(1, 1) == "/" then
        process_command(cb.data, cb.message.chat.id, cb.from.id)
    end
end

-- START BOT
bot.run({ timeout = 60 })
