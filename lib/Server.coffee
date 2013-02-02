{EventEmitter} = require 'events'
engineServer = require 'engine.io'

defaultAdapter =
  users: {}
  register: (req, cb) ->
    defaultAdapter.users[req.name] = req.socket.id
    cb()

  getId: (name, cb) -> 
    cb defaultAdapter.users[name]

  unregister: (req, cb) ->
    delete defaultAdapter.users[req.name]
    cb()

  getPresenceTargets: (req, cb) ->
    cb (id for user, id of defaultAdapter.users when user isnt req.name)

class Server extends EventEmitter
  constructor: (@httpServer, @options={}) ->
    @adapter = @options.adapter or defaultAdapter
    @options.path ?= "/holla"
    @options.destroyUpgrade ?= false
    @server = engineServer.attach @httpServer, @options
    @server.httpServer = @httpServer
    @server.on 'connection', @handleConnection

  updatePresence: (preq) ->
    return unless @options.presence
    @adapter.getPresenceTargets preq, (sockets) =>
      for id in sockets
        @server.clients[id]?.send JSON.stringify
          type: "presence"
          args:
            name: preq.name
            online: preq.online
    return

  handleConnection: (socket) =>
    socket.on 'error', @handleError.bind @, socket
    socket.on 'close', @handleClose.bind @, socket
    socket.on 'message', @handleMessage.bind @, socket

  handleMessage: (socket, msg) =>
    console.log socket.id, msg if @options.debug
    try
      msg = JSON.parse msg
    catch e
      return
    return unless msg.type and typeof msg.type is "string"
    return if msg.args and typeof msg.args isnt "object"

    if msg.type is "register"
      return unless msg.args
      return unless msg.args.name
      req =
        name: msg.args.name
        socket: socket
      @adapter.register req, (err) ->
        socket.identity ?= msg.args.name unless err?
        socket.send JSON.stringify
          type: "register"
          args:
            result: !err
            error: err

        preq =
          name: socket.identity
          socket: socket
          online: true
        @updatePresence preq

    else if msg.type is "offer"
      return unless msg.to
      return unless socket.identity
      @getId msg.to, (id) =>
        @server.clients[id]?.send JSON.stringify
          type: "offer"
          from: socket.identity

    else if msg.type is "hangup"
      return unless msg.to
      return unless socket.identity
      @getId msg.to, (id) =>
        @server.clients[id]?.send JSON.stringify
          type: "hangup"
          from: socket.identity

    else if msg.type is "answer"
      return unless msg.to
      return unless msg.args
      return unless msg.args.accepted?
      return unless socket.identity
      @getId msg.to, (id) =>
        @server.clients[id]?.send JSON.stringify
          type: "answer"
          from: socket.identity
          args:
            accepted: msg.args.accepted

    else if msg.type is "candidate"
      return unless msg.to
      return unless msg.args
      return unless msg.args.candidate
      return unless socket.identity
      @getId msg.to, (id) =>
        @server.clients[id]?.send JSON.stringify
          type: "candidate"
          from: socket.identity
          args:
            candidate: msg.args.candidate

    else if msg.type is "sdp"
      return unless msg.to
      return unless msg.args
      return unless msg.args.sdp
      return unless msg.args.type
      return unless socket.identity
      @getId msg.to, (id) =>
        @server.clients[id]?.send JSON.stringify
          type: "sdp"
          from: socket.identity
          args:
            sdp: msg.args.sdp
            type: msg.args.type

    else if msg.type is "chat"
      return unless msg.to
      return unless msg.args
      return unless msg.args.message
      return unless socket.identity
      @getId msg.to, (id) =>
        @server.clients[id]?.send JSON.stringify
          type: "chat"
          from: socket.identity
          args:
            message: msg.args.message

  handleError: (socket, err) =>
    req =
      name: socket.identity
      reason: err
      socket: socket
    @emit "error", req

  handleClose: (socket, reason) =>
    req =
      name: socket.identity
      reason: reason
      socket: socket

    @emit "close", req
    @adapter.unregister req, =>
      preq =
        name: socket.identity
        socket: socket
        online: false
      @updatePresence preq

module.exports = Server
