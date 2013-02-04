{join} = require 'path'
express = require "express"
holla = require "../index.js"

app = express()
app.use express.static __dirname
server = require('http').createServer(app).listen(8080)


rtc = holla.createServer server, {debug:true, presence:true}

console.log 'Server running on port 8080'