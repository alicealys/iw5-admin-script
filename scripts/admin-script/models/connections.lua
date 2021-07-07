return function(conn)
    return conn.define("connections", {
        {
            name = "id",
            type = "INTEGER",
            primarykey = true,
            autoincrement = true,
            allownull = false
        },
        {
            name = "player",
            type = "INTEGER",
            allownull = false,
            references = {
                model = "players",
                key = "id"
            }
        },
        {
            name = "address",
            type = "TEXT",
            allownull = false
        },
        {
            name = "date",
            type = "DATETIME",
            default = "CURRENT_TIMESTAMP",
            allownull = false
        }
    })   
end