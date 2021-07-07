return function(conn)
    return conn.define("players", {
        {
            name = "id",
            type = "INTEGER",
            primarykey = true,
            autoincrement = true,
            allownull = false
        },
        {
            name = "guid",
            type = "TEXT",
            allownull = false,
            unique = true
        },
        {
            name = "name",
            type = "TEXT",
            allownull = false
        },
        {
            name = "level",
            type = "INTEGER",
            default = 0,
            allownull = false
        },
        {
            name = "first_connection",
            type = "DATETIME",
            default = "CURRENT_TIMESTAMP",
            allownull = false
        }
    })    
end