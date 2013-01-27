{join} = require 'path'
connect = require "connect"
holla = require "../index.js"

app = connect()
app.use connect.static __dirname
server = app.listen 8080

rtc = holla.createServer server

users = {}
rtc.identify = (req, cb) ->
  users[req.name] = req.socket.id
  cb()

rtc.getId = (name, cb) ->
  cb users[name]

rtc.close = (req, cb) ->
  delete users[req.name]
  cb()


console.log 'Server running on port 8080'