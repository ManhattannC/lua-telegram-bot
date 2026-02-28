local copas = require('copas')
local telegram = require('telegram-bot-lua')

-- Token Loader
local function get_token_from_env()
    local f = io.open(".env", "r")
    if not f then
        print("Error: .env file not found")
        return nil
    end

    local token = nil
    for line in f:lines() do
        local value = line:match("BOT_TOKEN%s*=%s*(.+)")
        if value then
            token = value:gsub("^%s*(.-)%s*$", "%1"):gsub("['\"]", "")
            break
        end
    end
    f:close()
    return token
end

local token = get_token_from_env()

if not token or token == "" then
    print("Error: BOT_TOKEN not found in .env file")
    os.exit(1)
end

local bot = telegram.configure(token)
print("--- Bot is running (Token Loaded) ---")

-- Command Handlers
local commands = {}

-- /start command
function commands.start(chat_id, args)
    bot.send_message(chat_id, "Bot is online and ready.")
end

-- /help command
function commands.help(chat_id, args)
    local msg = [[
Available Commands:

/start - Check bot status
/help - Show this help
/ping - Test response
]]
    bot.send_message(chat_id, msg, { parse_mode = "Markdown" })
end

-- /ping command
function commands.ping(chat_id, args)
    bot.send_message(chat_id, "Pong!")
end

-- Unknown command handler
local function unknown_command(chat_id, cmd)
    bot.send_message(chat_id, "Unknown command: /" .. cmd .. "\nUse /help for available commands.")
end

-- Command Processor
local function process_command(text, chat_id)
    local cmd = text:match("^/(%w+)")

    if not cmd then return end

    local handler = commands[cmd:lower()]

    if handler then
        local ok, err = pcall(function()
            handler(chat_id)
        end)

        if not ok then
            print("Error in command /" .. cmd .. ": " .. tostring(err))
            bot.send_message(chat_id, "Command error. Please try again.")
        end
    else
        unknown_command(chat_id, cmd)
    end
end

-- Main Loop
local last_update_id = 0

copas.addthread(function()
    while true do
        local params = {
            offset = last_update_id + 1,
            timeout = 10
        }

        local ok, updates = pcall(function()
            return bot.get_updates(params)
        end)

        if ok and updates and updates.result then
            for _, update in ipairs(updates.result) do
                last_update_id = update.update_id

                -- Skip non-message updates
                if not update.message then return end

                -- Skip non-text messages
                if not update.message.text then return end

                local text = update.message.text
                local chat_id = update.message.chat.id
                local user_id = update.message.from.id
                local username = update.message.from.username
                local first_name = update.message.from.first_name
                print(">>> Chat from: " .. chat_id .. " | User ID: " .. user_id .. " | Username: " .. username .. " | First Name: " .. first_name .. " | Message: " .. text)

                -- Check if command, then process
                if text:sub(1, 1) == "/" then
                    process_command(text, chat_id)
                end
            end
        else
            print("Error fetching updates: " .. tostring(updates))
        end

        copas.sleep(0.5)
    end
end)

copas.loop()
