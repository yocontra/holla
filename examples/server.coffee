{join} = require 'path'
connect = require "connect"
holla = require "../index.js"

app = connect()
app.use connect.static __dirname
server = app.listen 8080

rtc = holla.createServer server

users = {}

# define how to assosciate a name with socket id
rtc.identify = (req, cb) ->
  users[req.name] = req.socket.id
  cb()
  rtc.selector req.name, (users) ->
    rtc.presence req.name, {online: true}, users
    return
  return

# define how to assosciate a socket id with name
rtc.getId = (name, cb) ->
  cb users[name]
  return

# define who gets presence notifications for user
rtc.selector = (name, cb) ->
  cb (id for user, id of users when user isnt name)

# define what happens when user disconnects
rtc.close = (req, cb) ->
  delete users[req.name]
  cb()
  rtc.selector req.name, (users) ->
    rtc.presence req.name, {online: false}, users
    return
  return


console.log 'Server running on port 8080'