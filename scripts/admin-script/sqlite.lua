local json = require("json")

function tablelength(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

local sqlite = {}

function sqlite.connect(url, password)
    local connection = {}

    local test = http.request(url, {}, true)
    test.onerror = function(error, code)
        print("Failed to connect to database (" .. url .. "): " .. error)
    end

    test.send()

    function connection.query(query, callback)
        callback = callback or function() end

        local request = http.request(url, {
            parameters = {
                password = password,
                query = query
            }
        }, true)
    
        request.onerror = function(error, code)
            error("SQLITE: HTTP Error executing query: " .. error)
        end
    
        request.onload = function(result)
            local obj = json.decode(result)
            if (not obj.success) then
                error("SQLITE: Query failed (" .. query .. "): " .. json.encode(obj.error))
            end
            callback(obj)
        end
    
        request.send()
    end
    
    function connection.define(name, values, callback)
        callback = callback or function() end

        local query = "CREATE TABLE IF NOT EXISTS " .. name .. "(\n"
        
        local foreignkeys = {}

        for i = 1, #values do
            query = query .. "\t"

            local value = string.format("%s %s %s %s %s %s %s",
                values[i].name,
                values[i].type,
                values[i].primarykey and "PRIMARY KEY" or "",
                values[i].autoincrement and "AUTOINCREMENT" or "",
                values[i].default and ("DEFAULT " .. values[i].default) or "",
                values[i].allownull and "" or "NOT NULL",
                values[i].unique and "UNIQUE" or ""
            )

            if (values[i].references) then
                table.insert(foreignkeys, string.format("FOREIGN KEY(%s) REFERENCES %s(%s)", 
                    values[i].name, 
                    values[i].references.model, 
                    values[i].references.key)
                )
            end

            query = query .. value

            if (i < #values or #foreignkeys > 0) then
                query = query .. ",\n"
            end
        end

        for i = 1, #foreignkeys do
            query = query .. "\t" .. foreignkeys[i]

            if (i < #foreignkeys) then
                query = query .. ",\n"
            end
        end

        query = query .. "\n)"

        connection.query(query, callback)

        local model = {}

        model.find = function(values, callback)
            connection.find(name, values, callback)
        end
        
        model.insert = function(values, callback)
            connection.insert(name, values, callback)
        end

        model.update = function(condition, values, callback)
            connection.update(name, condition, values, callback)
        end

        return model
    end

    function connection.find(table, values, callback)
        callback = callback or function() end

        local searchstring = ""
    
        local count = tablelength(values)
    
        local index = 1
        for k, v in pairs(values) do
            if (type(v) == "table") then
                searchstring = searchstring .. string.format("%s %s %s%s",
                    k,
                    v.type,
                    json.encode(v.value),
                    index < count and " and " or ""
                )
            else
                searchstring = searchstring .. string.format("%s = %s%s", 
                    k, 
                    json.encode(v),
                    index < count and " and " or ""
                )
            end

            index = index + 1
        end
    
        connection.query(string.format([[
            SELECT * FROM %s%s%s
        ]], table, index > 1 and " WHERE " or "", searchstring), 
        function(result)
            callback(result.result[1])
        end)
    end

    function connection.update(table, condition, values, callback)
        callback = callback or function() end

        local updatestring = ""
        local count = tablelength(values)

        local index = 1
        for k, v in pairs(values) do
            updatestring = updatestring .. string.format("%s = %s", k, json.encode(v))

            if (index < count) then
                updatestring = updatestring .. ","
            end

            index = index + 1
        end

        local searchstring = ""
        count = tablelength(condition)
    
        index = 1
        for k, v in pairs(condition) do
            if (type(v) == "table") then
                searchstring = searchstring .. string.format("%s %s %s%s",
                    k,
                    v.type,
                    json.encode(v.value),
                    index < count and " and " or ""
                )
            else
                searchstring = searchstring .. string.format("%s = %s%s", 
                    k, 
                    json.encode(v),
                    index < count and " and " or ""
                )
            end

            index = index + 1
        end

        connection.query(string.format([[
            UPDATE %s SET %s %s%s
        ]], table, updatestring,index > 1 and " WHERE " or "", searchstring), callback)
    end
    
    function connection.insert(table, _values, callback)
        callback = callback or function() end

        local keys = "("
        local values = "("
    
        local count = tablelength(_values)
    
        if (count == 0) then
            callback(false)
            return
        end
    
        local index = 1
        for k, v in pairs(_values) do
            keys = keys .. k .. (index < count and "," or "")
            values = values .. json.encode(v) .. (index < count and "," or "")
    
            index = index + 1
        end
    
        keys = keys .. ")"
        values = values .. ")"
    
        connection.query(string.format([[
            INSERT INTO %s %s values %s
        ]], table, keys, values), 
        function(result)
            callback(result)
        end)
    end

    return connection
end

return sqlite