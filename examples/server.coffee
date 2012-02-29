{join} = require 'path'
connect = require "connect"
Vein = require "../index.js"

app = connect()
app.use connect.static join __dirname, '..'
server = app.listen 8080

# Web sockets
vein = new Vein server
vein.add 'test', (reply, socket, hello) -> reply "Hello #{socket.remoteAddress}! You said '#{hello}'"
vein.add 'othertest', (reply, socket, hello) -> reply "Hello #{socket.remoteAddress} -  You said '#{hello}'"

console.log "Server listening"