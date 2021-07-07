const path      = require('path')
const sqlite3   = require('sqlite3').verbose()
const Sequelize = require('sequelize')
const http      = require('http')
const express   = require('express')
const app       = express()

const hostname = "127.0.0.1"
const port = 8000

const password = 'deeznutz'

const server = http.createServer(app)

app.use(express.json())
app.use(express.urlencoded())

server.listen(port, hostname, () => {
    console.log(`Server running at http://${hostname}:${port}/`);
})

new sqlite3.Database(path.join(__dirname, 'database.db'), (err) => {
    const sequelize = new Sequelize({
        host: 'localhost',
        dialect: 'sqlite',
        pool: {
            max: 5,
            min: 0,
            idle: 10000
        },
        logging: false,
        storage: path.join(__dirname, 'database.db')
    })

    app.post('/query', async (req, res) => {
        const query = req.body.query
        const value = {success: false, result: null, error: null}

        if (req.body.password != password) {
            value.error = 'Invalid password'
            res.end(JSON.stringify(value))
            return
        }

        sequelize.query(query)
        .then(result => {
            value.success = true
            value.result = result
            res.end(JSON.stringify(value))
        })
        .catch(err => {
            value.error = err
            res.end(JSON.stringify(value))
        })
    })
})