{join} = require 'path'
connect = require "connect"
Vein = require "../../index.js"

app = connect()
app.use connect.static __dirname
server = app.listen 8080

users = {}
checkUser = (name, socket) -> users[name] and users[name].id is socket.id

# Web sockets
vein = new Vein server
vein.add 'join', (send, socket, name) ->
  return unless name
  return send error: 'Invalid name' unless typeof name is 'string' and name.length > 0 and name.length < 10
  return send error: 'Name already in use' if users[name] and vein.clients.indexOf(users[name]) > -1
  users[name] = socket
  send.all name, Object.keys users

vein.add 'leave', (send, socket, name) ->
  return unless name
  return send error: 'Not authorized' unless checkUser name, socket
  delete users[name]
  send.all name, Object.keys users

vein.add 'message', (send, socket, name, message) ->
  return unless name and message
  return send error: 'Not authorized' unless checkUser name, socket
  return send error: 'Invalid message' unless typeof message is 'string' and message.length > -1 and message.length < 750
  message = message.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  send.all name, message

console.log "Server listening"