local json = require("json")
local sqlite = require("sqlite")

require("commands")

if (not io.fileexists(scriptdir() .. "/cfg/config.json")) then
    print("Config file not found")
    return
end

local config = json.decode(io.readfile(scriptdir() .. "/cfg/config.json"))

function tablelength(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

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

function ordinalsuffix(i)
    local j = i % 10
    local k = i % 100

    if (j == 1 and k ~= 11) then
        return i .. "st"
    end

    if (j == 2 and k ~= 12) then
        return i .. "nd"
    end

    if (j == 3 and k ~= 13) then
        return i .. "rd"
    end
    
    return i .. "th"
end

function addressislocal(address)
    return address == "127.0.0.1" or address == "0.0.0.0"
end

function getlocation(address, callback)
    if (addressislocal(address)) then
        address = ""
    end

    http.get("http://ip-api.com/json/" .. address, function(data, success)
        if (not success) then
            callback("Unknown")
            return
        end

        local obj = json.decode(data)
        callback(obj.country)
    end, true)
end

local conn = sqlite.connect(config.database.url, config.database.password)
local models = {}

local list = io.listfiles(scriptdir() .. "./models")
for i = 1, #list do
    local split = list[i]:split("/")
    local filename = split[#split]:split(".")[1]

    models[filename] = require("models/" .. filename)(conn)
end

function findplayer(condition)
    local players = game:getentarray("player", "classname")
    for i = 1, #players do
        if (condition(players[i])) then
            return players[i]
        end
    end
end

game:addcommand("setlevel", function(args)
    if (#args < 3) then
        print("Usage: setlevel <name|id> <level>")
    end

    local searchbyid = false
    local name = args[2]
    local level = tonumber(args[3])
    if (level == nil or level < 0 or level > 10) then
        print("Invalid level value")
        return
    end

    local condition = {name = {type = "LIKE", value = "%" ..name .. "%"}}
    searchbyid = name:sub(1, 1) == "@"
    if (searchbyid) then
        local id = tonumber(name:sub(2, -1))
        if (id == nil) then
            print("Invalid id")
        end

        condition = {id = id}
    end

    models.players.find(condition, function(players)
        if (#players < 0) then
            print("Player not found")
            return
        end

        models.players.update({
            id = players[1].id
        }, {
            level = level
        }, function(result)
            print("Set " .. players[1].name .. "'s level to " .. level)
            local id = players[1].id
            game:ontimeout(function()
                local found = findplayer(function(_player)
                    return _player.id == id
                end)

                if (found ~= nil) then
                    found.level = level
                    found:tell("Your level has been set to " .. level)
                end
            end, 0)
        end)
    end)
end)

function entity:getplayerinstance(callback)
    local guid = self:getguid()
    local name = self.name

    models.players.find({
        guid = guid
    }, function(result)
        if (#result < 1) then
            models.players.insert({
                guid = guid,
                name = name
            }, function()
                models.players.find({
                    guid = guid
                }, function(result)
                    callback(result[1])
                end)
            end)
        else
            callback(result[1])
        end
    end)
end

function entity:kick(reason)
    game:executecommand("clientkick " .. self:getentitynumber() .. "\"" .. reason .. "\"")
end

level:onnotify("connected", function(player)
    local guid = player:getguid()
    local name = player.name
    local address = player.address

    local entnum = player:getentitynumber()
    local wasconnected = pers["slot_" .. entnum] == guid

    pers["slot_" .. entnum] = guid

    player:getplayerinstance(function(result)
        local id = result.id

        game:ontimeout(function()
            player.id = id
            player.level = result.level
        end, 0)

        if (wasconnected) then
            return
        end

        models.connections.insert({
            player = id,
            address = address
        })

        models.connections.find({
            player = id
        }, function(result)
            game:ontimeout(function()
                player:tell(string.format("Welcome ^5%s^7 this is your ^5%s^7 connection!", name, ordinalsuffix(#result)))
            end, 0)

            getlocation(address, function(location)
                game:ontimeout(function()
                    game:say(string.format("^5%s^7 hails from ^5%s", name, location))
                end, 0)
            end)
        end)
    end)

    player:onnotifyonce("disconnect", function()
        pers["slot_" .. entnum] = nil
    end)
end)