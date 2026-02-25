local copas = require('copas') 
local telegram = require('telegram-bot-lua') 

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
    os.exit()
end

local bot = telegram.configure(token)
print("--- Bot is running (Token Loaded) ---")

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
                
                if update.message and update.message.text then
                    local text = update.message.text
                    local chat_id = update.message.chat.id
                    print(">>> Chat from: " .. chat_id .. " | Message: " .. text)
                    
                    if text == "/start" then
                        pcall(function()
                            bot.send_message(chat_id, "I'm Here")
                        end)
                    end
                end
            end
        end
        copas.sleep(0.5)
    end
end)

copas.loop()