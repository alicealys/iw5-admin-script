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
    local command = {callbacks = {}, level = 0, description = "Not defined", usage = "Not defined", minargs = 0}
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

    function command.setusage(usage)
        command.usage = usage

        return command
    end

    function command.setdescription(description)
        command.description = description

        return command
    end

    function command.setminargs(count)
        command.minargs = count

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

local commandprefix = config.commandprefix or "!"

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

            if (#args < command.minargs) then
                player:tell("Insufficient arguments, Usage: ^3" .. command.usage)
                return true
            end

            command.execute(player, args)
            return true
        end
    end
end)

function findplayerbyname(name)
    local players = game:getentarray("player", "classname")

    for i = 1, #players do
        local player = players[i]

        if (string.lower(player.name):find(string.lower(name))) then
            return player
        end
    end
end

function table.chunk(t, size)
    local chunks = {}
    
    local index = 1
    for i = 1, #t, size do
        chunks[index] = {}
        for o = 0, size - 1 do
            table.insert(chunks[index], t[i + o])
        end
        index = index + 1
    end

    return chunks
end

commands.add(
    commands.new("help")
    .setalias("h")
    .setlevel(0)
    .setdescription("Disable the list of commands")
    .setusage("%shelp [page]")
    .addcallback(function(player, args)
        local validcmds = {}

        for i = 1, #commands.commands do
            if (commands.commands[i].level <= player.level) then
                table.insert(validcmds, commands.commands[i])
            end
        end

        local chunks = table.chunk(validcmds, 4)
        local page = tonumber(args[2]) or 1
        page = math.max(1, math.min(page, #chunks))

        player:tell(string.format("^3---- Page %i / %i -----", page, #chunks))

        for i = 1, #chunks[page] do
            game:ontimeout(function()
                player:tell(string.format("^6%s%s^7: %s^7, Usage: ^3%s",
                    commandprefix,
                    chunks[page][i].name,
                    chunks[page][i].description,
                    string.format(chunks[page][i].usage, commandprefix)
                ))
            end, 500 * (i - 1))
        end
    end)
)

commands.add(
    commands.new("suicide")
    .setalias("s")
    .setdescription("Kill yourself")
    .setusage("%ssuicide")
    .setlevel(0)
    .addcallback(function(player, args)
        player:suicide()
    end)
)

commands.add(
    commands.new("give")
    .setlevel(3)
    .setdescription("Give yourself or someone a weapon")
    .setusage("give <weapon|player> [weapon]")
    .setminargs(2)
    .addcallback(function(player, args)
        if (#args == 2) then
            local weapon = args[2]
            if (game:weaponclass(weapon) == "none") then
                player:tell("Invalid weapon")
                return
            end

            player:giveweapon(weapon)
            player:switchtoweapon(weapon)
            return
        end

        if (#args == 3) then
            local target = findplayerbyname(args[2])
            local weapon = args[3]

            if (target == nil) then
                player:tell("Player not found")
                return
            end

            if (game:weaponclass(weapon) == "none") then
                player:tell("Invalid weapon")
                return
            end

            target:giveweapon(weapon)
            target:switchtoweapon(weapon)
        end
    end)
)

commands.add(
    commands.new("noclip")
    .setlevel(3)
    .setdescription("Enable/disable noclip")
    .setusage("%snoclip")
    .addcallback(function(player, args)
        player.clientflags = player.clientflags ~ 1
        player:tell("Noclip " .. (player.clientflags & 1 ~= 0 and "^2ON" or "^1OFF"))
    end)
)

commands.add(
    commands.new("ufo")
    .setlevel(3)
    .setdescription("Enable/disable ufo")
    .setusage("%sufo")
    .addcallback(function(player, args)
        player.clientflags = player.clientflags ~ 2
        player:tell("Ufo " .. (player.clientflags & 2 ~= 0 and "^2ON" or "^1OFF"))
    end)
)

commands.add(
    commands.new("god")
    .setlevel(3)
    .setdescription("Enable/disable godmode")
    .setusage("%sgod")
    .addcallback(function(player, args)
        player.flags = player.flags ~ 1
        player:tell("Godmode " .. (player.flags & 1 ~= 0 and "^2ON" or "^1OFF"))
    end)
)

commands.add(
    commands.new("demigod")
    .setlevel(3)
    .setdescription("Enable/disable demigod mode")
    .setusage("%sdemigod")
    .addcallback(function(player, args)
        player.flags = player.flags ~ 2
        player:tell("Demigod mode " .. (player.flags & 2 ~= 0 and "^2ON" or "^1OFF"))
    end)
)