{join} = require 'path'
connect = require "connect"
Vein = require "../../index.js"

app = connect()
app.use connect.static __dirname
server = app.listen 8080

vein = new Vein server, path: '/chat'

vein.use (req, res, next) ->
  console.log res.socket.req.url
  next()

vein.add 'join', (res, name) ->
  return res.send 'Invalid name' unless name? and typeof name is 'string' and name.length > 0
  res.cookie('username', name).send().publish name

vein.add 'leave', (res) ->
  res.send().publish res.cookie 'username'

vein.add 'message', (res, message) ->
  res.send().publish res.cookie('username'), message

console.log "Server listening"