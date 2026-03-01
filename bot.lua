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

-- log function
local function log(msg)
    print(string.format("[%s] %s", os.date("%Y-%m-%d %H:%M:%S"), msg))
end

-- Media
local media = {
    photo = {
        file_id = "",
        file_path = ""
    },
    video = {
        file_id = "",
        file_path = ""
    },
    document = {
        file_id = "",
        file_path = ""
    },
    sticker = {
        file_id = "",
        file_path = ""
    },
    voice = {
        file_id = "",
        file_path = ""
    },
    audio = {
        file_id = "",
        file_path = ""
    },
    animation = {
        file_id = "",
        file_path = ""
    }
}

-- Media helper
local function send_sticker(chat_id, sticker_id)
    bot.send_sticker(chat_id, sticker_id)
end

local function send_photo(chat_id, photo_id)
    bot.send_photo(chat_id, photo_id)
end

local function send_video(chat_id, video_id)
    bot.send_video(chat_id, video_id)
end

local function send_document(chat_id, document_id)
    bot.send_document(chat_id, document_id)
end

local function send_voice(chat_id, voice_id)
    bot.send_voice(chat_id, voice_id)
end

local function send_audio(chat_id, audio_id)
    bot.send_audio(chat_id, audio_id)
end

local function send_animation(chat_id, animation_id)
    bot.send_animation(chat_id, animation_id)
end

-- Command Handlers
local commands = {}

-- /start command
function commands.start(chat_id, args)
    bot.send_message(chat_id, "Bot is online and ready.")
end

-- /help command
function commands.help(chat_id, args)
    local msg = "Available Commands:"
    local keyboard = {
        {
            { text = "/start", callback_data = "/start" },
            { text = "/ping", callback_data = "/ping" }
        },
        {
            { text = "/help", callback_data = "/help" }
        }
    }

    bot.send_message(chat_id, msg, { parse_mode = "Markdown", reply_markup = { inline_keyboard = keyboard } })
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
    local cmd, args = text:match("^/(%w+)@?%S*%s*(.*)")
    if not cmd then return end

    local handler = commands[cmd:lower()]

    if handler then
        bot.send_chat_action(chat_id, "typing")
        copas.sleep(0.5)
        local ok, err = pcall(function()
            handler(chat_id, args)
        end)

        if not ok then
            log("Error in command /" .. cmd .. ": " .. tostring(err))
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
            timeout = 1
        }

        local ok, updates = pcall(function()
            return bot.get_updates(params)
        end)

        if ok and updates and updates.result then
            for _, update in ipairs(updates.result) do
                last_update_id = update.update_id

                -- Callback Query Handler
                if update.callback_query then
                    local callback_data = update.callback_query.data
                    local callback_chat_id = update.callback_query.message.chat.id
                    local callback_id = update.callback_query.id
                    local message_id = update.callback_query.message.message_id

                    bot.delete_message(callback_chat_id, message_id)
                    bot.answer_callback_query(callback_id)

                    if callback_data:sub(1, 1) == "/" then
                        process_command(callback_data, callback_chat_id)
                    end

                    goto continue
                end


                -- Debug media
                if update.message and update.message.photo then
                    log(">>> Photo: " .. update.message.photo[1].file_id)
                end

                if update.message and update.message.video then
                    log(">>> Video: " .. update.message.video.file_id)
                end

                if update.message and update.message.document then
                    log(">>> Document: " .. update.message.document.file_id)
                end

                if update.message and update.message.sticker then
                    log(">>> Sticker: " .. update.message.sticker.file_id)
                end

                if update.message and update.message.voice then
                    log(">>> Voice: " .. update.message.voice.file_id)
                end

                if update.message and update.message.audio then
                    log(">>> Audio: " .. update.message.audio.file_id)
                end

                if update.message and update.message.animation then
                    log(">>> Animation: " .. update.message.animation.file_id)
                end

                -- skip non-message updates
                if not update.message or not update.message.text then 
                    goto continue
                end

                local text = update.message.text
                local chat_id = update.message.chat.id
                local user_id = update.message.from.id
                local username = update.message.from.username or "N/A"
                local first_name = update.message.from.first_name or "Unknown"
                log(">>> Chat from: " .. chat_id .. " | User ID: " .. user_id .. " | Username: " .. username .. " | First Name: " .. first_name .. " | Message: " .. text)

                -- Check if command, then process
                if text:sub(1, 1) == "/" then
                    process_command(text, chat_id)
                end

                ::continue::
            end
        else
            log("Error fetching updates: " .. tostring(updates))
        end

        copas.sleep(0.5)
    end
end)

copas.loop()
