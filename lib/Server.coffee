socketio = require 'socket.io'
base64id = require 'base64id'
RedisStore = require 'socket.io/lib/stores/redis'
redis  = require 'socket.io/node_modules/redis'
hookify = require 'hookify'

class Server extends hookify
  constructor: (@httpServer, @options={}) ->
    super
    @io = socketio.listen @httpServer
    @io.set 'log level', (if @options.debug then 3 else 0)
    @io.set 'browser client minification', !@options.debug
    @io.set 'browser client gzip', !@options.debug
    @io.set 'browser client etag', !@options.debug
    if @options.redis
      @io.set 'store', new RedisStore
        redis: redis
        redisPub: @options.redis.pub
        redisSub: @options.redis.sub
        redisClient: @options.redis.store
    else
      @clients = {}

    @io.sockets.on 'connection', @handleConnection

  handleConnection: (socket) =>
    @runPre 'handle', [socket], =>
      socket.on "register", @register.bind @, socket
      socket.on "unregister", @unregister.bind @, socket
      socket.on "createCall", @createCall.bind @, socket
      socket.on "endCall", @endCall.bind @, socket
      socket.on "addUser", @addUser.bind @, socket
      socket.on "sendSDPOffer", @sendSDPOffer.bind @, socket
      socket.on "sendSDPAnswer", @sendSDPAnswer.bind @, socket
      socket.on "sendCandidate", @sendCandidate.bind @, socket
      socket.on "disconnect", @userDisconnect.bind @, socket
      @runPost 'handle', [socket], =>

  # exposed services
  register: (socket, name, cb) =>
    return cb "Invalid name" unless typeof name is 'string' and name.length > 0
    @runPre 'register', [socket, name], =>
      if @options.identityProvider
        @options.identityProvider socket, name, (err, newName) =>
          return cb err if err?
          @registerSocket socket, newName, cb
      else
        @registerSocket socket, name, cb

  unregister: (socket, cb) =>
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      @runPre 'unregister', [socket, identity], =>
        rooms = @io.sockets.manager.roomClients[socket.id]
        if rooms?
          for name, room of rooms
            callId = name[1..]
            @io.sockets.in(callId).emit "#{callId}:end"

        socket.del 'identity', (err) =>
          return cb err if err?
          if @options.redis
            @options.redis.store.hdel "clients", identity, (err) =>
              return cb err if err?
              cb()
          else
            delete @clients[identity]
            cb()

          @runPost 'unregister', [socket, identity], =>

  createCall: (socket, cb) =>
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      @runPre 'call', [socket, identity], =>
        callId = @generateId()
        return cb "Call ID conflict" if @io.rooms[callId]?
        socket.join callId
        cb null, callId
        @runPost 'call', [socket, identity, callId], =>

  endCall: (socket, callId, cb) =>
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb "Not in room" unless inRoom
      @runPre 'endCall', [socket, identity, callId], =>
        @io.sockets.in(callId).emit "#{callId}:end"
        sock.leave(callId) for sock in @io.sockets.in(callId).clients()
        cb()
        @runPost 'endCall', [socket, identity, callId], =>

  addUser: (socket, callId, userIdentity, cb) =>
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      return cb "Why would you try to call yourself?" if identity is userIdentity
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb "Not in room" unless inRoom
      @getSocketFromIdentity userIdentity, (err, socket) =>
        return cb err if err?
        roomInfo =
          id: callId
          caller: identity
        @runPre 'addUser', [socket, identity, userIdentity, callId], =>
          @askSocketToJoin socket, roomInfo, (err, wantsToJoin) =>
            return cb err if err?
            return cb "Call declined" unless wantsToJoin
            @io.sockets.in(callId).emit "#{callId}:userAdded", userIdentity
            socket.join callId
            cb()
            @runPost 'addUser', [socket, identity, userIdentity, callId, wantsToJoin], =>

  sendSDPOffer: (socket, callId, userIdentity, desc, cb) =>
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb "Not in room" unless inRoom
      @getSocketFromIdentity userIdentity, (err, socket) =>
        return cb err if err?
        socket.emit "#{callId}:#{identity}:sdp", desc
        cb()
  
  sendSDPAnswer: (socket, callId, userIdentity, desc, cb) =>
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb "Not in room" unless inRoom
      @getSocketFromIdentity userIdentity, (err, socket) =>
        return cb err if err?
        socket.emit "#{callId}:#{identity}:sdp", desc
        cb()

  sendCandidate: (socket, callId, userIdentity, desc, cb) =>
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      inRoom = @io.sockets.manager.roomClients[socket.id]?["/#{callId}"]
      return cb "Not in room" unless inRoom
      @getSocketFromIdentity userIdentity, (err, socket) =>
        return cb err if err?
        socket.emit "#{callId}:#{identity}:candidate", desc
        cb()

  sendPresence: (socket, status, cb) =>
    @getIdentityFromSocket socket, (err, identity) =>
      return cb err if err?
      #socket.broadcast.emit 'presenceChange', identity, status
      @runPre 'presence', [socket, identity, status], =>
        cb()
        @runPost 'presence', [socket, identity, status], =>

  userDisconnect: (socket) =>
    @sendPresence socket, 'offline', (err) =>
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
    if @options.redis
      @options.redis.store.hget "clients", identity, (err, sid) =>
        return cb err if err?
        return cb "Requested identity not registered" unless sid?
        @getSocketById sid, cb
    else
      sid = @clients[identity]
      return cb "Requested identity not registered" unless sid?
      @getSocketById sid, cb

  askSocketToJoin: (socket, roomInfo, cb) ->
    socket.emit "callRequest", roomInfo
    socket.once "#{roomInfo.id}:callResponse", (res) -> cb null, res

  registerSocket: (socket, name, cb) ->
    @getSocketFromIdentity name, (err, sock) =>
      good = err? and ((err is "Socket does not exist") or (err is "Requested identity not registered"))
      return cb err if !good
      return cb "Name already taken" if sock?
      @getIdentityFromSocket socket, (err, identity) =>
        return cb "Already registered" if identity?
        return cb err if err? and err isnt "Not registered"

        socket.set 'identity', name, (err) =>
          return cb err if err?
          if @options.redis
            @options.redis.store.hset "clients", name, socket.id, (err) =>
              return cb err if err?
              cb null, name
          else
            @clients[name] = socket.id
            cb null, name

          @sendPresence socket, 'online', (err) =>
            @runPost 'register', [socket, name], =>

module.exports = Server