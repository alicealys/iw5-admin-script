local json = require("json")

local discord = {}
discord.webhook = {}
discord.messagebuilder = {}

function string:split(sep)
    if sep == nil then
            sep = "%s"
    end

    local t = {}

    for str in string.gmatch(self, "([^" .. sep .. "]+)") do
            table.insert(t, str)
    end

    return t
end

local function formatcolor(color)
    if (type(color) == "string" and color:sub(1, 1) == "#") then
        local hex = color:split('#')[2]

        return tonumber(hex, 16)
    else
        return tonumber(color)
    end
end

function discord.webhook.new(url)
    local webhook = {}
    webhook.url = url

    function webhook.setusername(username)
        webhook.username = username

        return webhook
    end

    function webhook.setavatar(avatarurl)
        webhook.avatarurl = avatarurl

        return webhook
    end

    function webhook.send(message, callback)
        callback = callback or function() end
        local payload = {}

        if (type(message) == "string") then
            payload.username = webhook.username
            payload.avatar_url = webhook.avatarurl
            payload.content = message
        else
            message.payload.username = webhook.username
            message.payload.avatar_url = webhook.avatarurl
            payload = message.payload
        end

        local request = http.request(webhook.url, {
            headers = {
                ["Content-Type"] = "application/json"
            },
            body = json.encode(payload)
        }, true)

        request.onerror = function(error, code)
            error("Discord: error sending message: " .. error)
        end

        request.onload = function(data)
            callback(data)
        end

        request.send()
    end

    return webhook
end

function discord.messagebuilder.new()
    local message = {
        payload = {
            embeds = {{fields = {}}}
        }
    }

    function message.getjson()
        return message.payload
    end

    function message.settext(text)
        message.payload.content = text

        return message
    end

    function message.setauthor(author, authorimage, authorurl)
        message.payload.embeds[1].author = {}
        message.payload.embeds[1].author.name = author
        message.payload.embeds[1].author.url = authorurl
        message.payload.embeds[1].author.icon_url = authorimage

        return message
    end

    function message.settitle(title)
        message.payload.embeds[1].title = title

        return message
    end

    function message.seturl(url)
        message.payload.embeds[1].url = url

        return message
    end

    function message.setthumbnail(thumbnail)
        message.payload.embeds[1].thumbnail = {}
        message.payload.embeds[1].thumbnail.url = thumbnail

        return message
    end

    function message.setimage(image)
        message.payload.embeds[1].image = {}
        message.payload.embeds[1].image.url = image

        return message
    end

    function message.settimestamp(date)
        if (date) then
            message.payload.embeds[1].timestamp = date
        else
            message.payload.embeds[1].timestamp = os.date("%Y-%m-%dT%H:%M:%S%z")
        end

        return message
    end

    function message.setcolor(color)
        message.payload.embeds[1].color = formatcolor(color)

        return message
    end

    function message.setdescription(description)
        message.payload.embeds[1].description = description

        return message
    end

    function message.addfield(fieldName, fieldValue, inline)
        table.insert(message.payload.embeds[1].fields, {
            name = fieldName,
            value = fieldValue,
            inline = inline
        })

        return message
    end

    function message.setfooter(footer, footerImage)
        message.payload.embeds[1].footer = {}
        message.payload.embeds[1].footer.icon_url = footerImage
        message.payload.embeds[1].footer.text = footer

        return message
    end

    return message
end

return discord