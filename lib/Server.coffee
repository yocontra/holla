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
    socket.on "endCall", @endCall.bind @, socket
    socket.on "addUser", @addUser.bind @, socket
    socket.on "sendSDPOffer", @sendSDPOffer.bind @, socket
    socket.on "sendSDPAnswer", @sendSDPAnswer.bind @, socket
    socket.on "sendCandidate", @sendCandidate.bind @, socket
    socket.on "disconnect", @userDisconnect.bind @, socket

  # exposed services
  register: (socket, name, cb) =>
    console.log "register", socket.id, name
    return cb "Invalid name" unless typeof name is 'string' and name.length > 0
    return cb "Name already taken" if @clients[name]?
    @getIdentityFromSocket socket, (err, identity) =>
      return cb "Already registered" if identity?
      return cb err if err? and err isnt "Not registered"

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
      return cb "Call ID conflict" if @io.rooms[callId]?
      socket.join callId
      @calls[callId] = @io.rooms[callId]
      cb null, callId

  endCall: (socket, callId, cb) =>
    console.log "addUser", socket.id, callId
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb "Not in room" unless inRoom
      @io.sockets.in(callId).emit "#{callId}:end"
      sock.leave(callId) for sock in @io.sockets.in(callId).clients()
      delete @calls[callId]

      cb()

  addUser: (socket, callId, userIdentity, cb) =>
    console.log "addUser", socket.id, callId, userIdentity
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb "Not in room" unless inRoom
      @getSocketFromIdentity userIdentity, (err, socket) =>
        return cb err if err?
        roomInfo =
          id: callId
          caller: identity
        @askSocketToJoin socket, roomInfo, (err, wantsToJoin) =>
          return cb err if err?
          return cb "Call declined" unless wantsToJoin
          @io.sockets.in(callId).emit "#{callId}:userAdded", userIdentity
          socket.join callId
          cb()

  sendSDPOffer: (socket, callId, userIdentity, desc, cb) =>
    console.log "sendSDPOffer", socket.id, callId, userIdentity, desc
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb "Not in room" unless inRoom
      @getSocketFromIdentity userIdentity, (err, socket) =>
        return cb err if err?
        socket.emit "#{callId}:#{identity}:sdp", desc
        cb()
  
  sendSDPAnswer: (socket, callId, userIdentity, desc, cb) =>
    console.log "sendSDPAnswer", socket.id, callId, userIdentity, desc
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb "Not in room" unless inRoom
      @getSocketFromIdentity userIdentity, (err, socket) =>
        return cb err if err?
        socket.emit "#{callId}:#{identity}:sdp", desc
        cb()

  sendCandidate: (socket, callId, userIdentity, desc, cb) =>
    console.log "sendCandidate", socket.id, callId, userIdentity, desc
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb "Not in room" unless inRoom
      @getSocketFromIdentity userIdentity, (err, socket) =>
        return cb err if err?
        socket.emit "#{callId}:#{identity}:candidate", desc
        cb()

  userDisconnect: (socket) =>
    console.log "disconnect", socket.id
    @unregister socket, (err) =>

  # utility crap
  generateId: => base64id.generateId()
  getSocketById: (id, cb) =>
    socket = @io.sockets.sockets[id]
    return cb "Socket does not exist" unless socket?
    cb null, socket

  getIdentityFromSocket: (socket, cb) =>
    socket.get 'identity', (err, identity) ->
      return cb err if err?
      return cb "Not registered" unless identity?
      return cb null, identity

  getSocketFromIdentity: (identity, cb) =>
    sid = @clients[identity]
    return cb "Requested identity not registered" unless sid?
    @getSocketById sid, cb

  askSocketToJoin: (socket, roomInfo, cb) ->
    socket.emit "callRequest", roomInfo
    socket.once "#{roomInfo.id}:callResponse", (res) -> cb null, res

module.exports = Server