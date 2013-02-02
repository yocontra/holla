{join} = require 'path'
connect = require "connect"
holla = require "../index.js"

app = connect()
app.use connect.static __dirname
server = app.listen 8080

rtc = holla.createServer server, {debug:true, presence:true}


console.log 'Server running on port 8080'