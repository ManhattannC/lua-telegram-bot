-- media.lua

local M = {}

M.types = {
    photo = function(m) return m.photo and m.photo[#m.photo].file_id end,
    video = function(m) return m.video and m.video.file_id end,
    audio = function(m) return m.audio and m.audio.file_id end,
    document = function(m) return m.document and m.document.file_id end,
    voice = function(m) return m.voice and m.voice.file_id end,
    sticker = function(m) return m.sticker and m.sticker.file_id end,
    animation = function(m) return m.animation and m.animation.file_id end,
}

M.stickers = {}
M.animations = {}
M.photos = {}

function M.send_sticker(chat_id, bot, file_id)
    bot.send_sticker(chat_id, file_id)
end

function M.send_animation(chat_id, bot, file_id)
    bot.send_animation(chat_id, file_id)
end

function M.send_photo(chat_id, bot, file_id)
    bot.send_photo(chat_id, file_id)
end

function M.send_video(chat_id, bot, file_id)
    bot.send_video(chat_id, file_id)
end

function M.send_audio(chat_id, bot, file_id)
    bot.send_audio(chat_id, file_id)
end

function M.send_document(chat_id, bot, file_id)
    bot.send_document(chat_id, file_id)
end

function M.send_voice(chat_id, bot, file_id)
    bot.send_voice(chat_id, file_id)
end

function M.log_media(message, log_fn)
    for media_type, get_id in pairs(M.types) do
        local file_id = get_id(message)
        if file_id then
            log_fn(string.format(">> %s: %s", media_type:upper(), file_id))
        end
    end
end

return M
    