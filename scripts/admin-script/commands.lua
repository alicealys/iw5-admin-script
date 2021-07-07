local json = require("json")
local config = {}
local configpath = scriptdir() .. "/cfg/config.json"

if (not io.fileexists(configpath)) then
    print("Config file not found")
else
    config = json.decode(io.readfile(scriptdir() .. "/cfg/config.json"))
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

local commands = {commands = {}}
local levels = {}

function commands.new(name)
    local command = {callbacks = {}, level = 0}
    command.name = name

    function command.setname(name)
        command.name = name:lower()
        return command
    end

    function command.setalias(alias)
        command.alias = alias:lower()
        return command
    end

    function command.setlevel(level)
        command.level = level
        return command
    end

    function command.addcallback(callback)
        table.insert(command.callbacks, callback)
        return command
    end

    function command.execute(player, args)
        for i = 1, #command.callbacks do
            local result = pcall(function()
                command.callbacks[i](player, args)
            end)

            if (not result) then
                player:tell("Internal error executing command")
            end
        end
    end

    return command
end

function commands.add(command)
    table.insert(commands.commands, command)
end

local commandprefix = "!"

game:onplayersay(function(player, message, teamchat)
    if (message:sub(1, 1) ~= commandprefix) then
        return
    end

    local args = message:split()
    local name = args[1]:sub(2, -1):lower()

    for i = 1, #commands.commands do
        local command = commands.commands[i]

        if (command.name == name or command.alias == name) then
            if (command.level > player.level) then
                player:tell("Insufficient permissions")
                return true
            end

            game:ontimeout(function()
                command.execute(player, args)
            end, 0)
            return true
        end
    end
end)

commands.add(
    commands.new("suicide")
    .setalias("s")
    .setlevel(0)
    .addcallback(function(player, args)
        player:suicide()
    end)
)