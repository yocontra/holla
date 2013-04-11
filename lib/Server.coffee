{EventEmitter} = require 'events'
socketio = require 'socket.io'
base64id = require 'base64id'

class Server extends EventEmitter
  constructor: (@httpServer, @options={}) ->
    @clients = {}
    @calls = {}
    @io = socketio.listen @httpServer
    @io.sockets.on 'connection', @handleConnection

  handleConnection: (socket) =>
    socket.on "register", @register.bind @, socket
    socket.on "unregister", @unregister.bind @, socket
    socket.on "createCall", @createCall.bind @, socket
    socket.on "addUser", @addUser.bind @, socket
    socket.on "disconnect", @userDisconnect.bind @, socket

  # exposed services
  register: (socket, name, cb) =>
    console.log "register", socket.id, name
    return cb new Error "Invalid name" unless typeof name is 'string' and name.length > 0
    return cb new Error "Name already taken" if @clients[name]?
    @getIdentityFromSocket socket, (err, identity) =>
      return cb new Error "Already registered" if identity?
      return cb err if err? and err.message isnt "Not registered"

      socket.set 'identity', name, (err) =>
        return cb err if err?
        @clients[name] = socket.id
        cb()

  unregister: (socket, cb) =>
    console.log "unregister", socket.id
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      socket.del 'identity', (err) =>
        return cb err if err?
        delete @clients[identity]
        cb()

  createCall: (socket, cb) =>
    console.log "createCall", socket.id
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      callId = @generateId()
      return cb new Error "Call ID conflict" if @io.rooms[callId]?
      socket.join callId
      @calls[callId] = @io.rooms[callId]
      cb null, callId

  addUser: (socket, callId, userIdentity, cb) =>
    console.log "addUser", socket.id, callId, userIdentity
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb new Error "Not in room" unless inRoom
      @getSocketFromIdentity userIdentity, (err, socket) =>
        return cb err if err?
        roomInfo =
          id: callId
          caller: identity
        @askSocketToJoin socket, roomInfo, (err, wantsToJoin) =>
          return cb err if err?
          return cb new Error "Call declined" unless wantsToJoin
          socket.broadcast.to(callId).emit "#{callId}:userAdded", userIdentity
          socket.join callId
          cb()

  userDisconnect: (socket) =>
    console.log "disconnect", socket.id
    @unregister socket, (err) =>

  # utility crap
  generateId: => base64id.generateId()
  getSocketById: (id, cb) =>
    socket = @io.sockets.sockets[id]
    return cb new Error "Socket does not exist" unless socket?
    cb null, socket

  getIdentityFromSocket: (socket, cb) =>
    socket.get 'identity', (err, identity) ->
      return cb err if err?
      return cb new Error "Not registered" unless identity?
      return cb null, identity

  getSocketFromIdentity: (identity, cb) =>
    sid = @clients[identity]
    return cb new Error "Request identity not registered" unless sid?
    @getSocketById sid, cb

  askSocketToJoin: (socket, roomInfo, cb) ->
    socket.emit "callRequest", roomInfo
    socket.once "#{roomInfo.id}:callResponse", (res) -> cb null, res

module.exports = Server