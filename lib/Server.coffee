{EventEmitter} = require 'events'
engineServer = require 'engine.io'

defaultAdapter =
  users: {}
  register: (req, cb) ->
    @users[req.name] = req.socket.id
    cb()

  getId: (name, cb) -> 
    cb @users[name]

  unregister: (req, cb) ->
    delete @users[req.name]
    cb()

  getPresenceTargets: (req, cb) ->
    cb (id for user, id of @users when user isnt req.name)

class Server extends EventEmitter
  constructor: (@httpServer, @options={}) ->
    @adapter = {}
    for k,v of defaultAdapter
      if typeof v is "function"
        @adapter[k]=v.bind @adapter
      else
        @adapter[k]=v

    if @options.adapter
      for k,v of @options.adapter
        if typeof v is "function"
          @adapter[k]=v.bind @adapter
        else
          @adapter[k]=v

    @options.presence ?= true
    @options.debug ?= false
    @options.path ?= "/holla"
    @options.destroyUpgrade ?= false
    @server = engineServer.attach @httpServer, @options
    @server.httpServer = @httpServer
    @server.on 'connection', @handleConnection

    if @options.presence
      @on 'register', (req) =>
        @updatePresence
          name: req.socket.identity
          socket: req.socket
          online: true

      @on 'unregister', (req) =>
        @updatePresence
          name: req.socket.identity
          socket: req.socket
          online: false

  updatePresence: (preq) ->
    @adapter.getPresenceTargets preq, (sockets) =>
      for id in sockets
        @server.clients[id]?.send JSON.stringify
          type: "presence"
          args:
            name: preq.name
            online: preq.online
      return
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
      @adapter.register req, (err) =>
        unless err?
          socket.identity ?= msg.args.name
          @emit "register", req
        socket.send JSON.stringify
          type: "register"
          args:
            result: !err

    else if msg.type is "offer"
      return unless msg.to
      return unless socket.identity
      @adapter.getId msg.to, (id) =>
        return unless @server.clients[id]?
        @server.clients[id].send JSON.stringify
          type: "offer"
          from: socket.identity

        req =
          name: socket.identity
          socket: socket.identity
          to: msg.to

        @emit "offer", req

    else if msg.type is "hangup"
      return unless msg.to
      return unless socket.identity
      @adapter.getId msg.to, (id) =>
        @server.clients[id]?.send JSON.stringify
          type: "hangup"
          from: socket.identity

        req =
          name: socket.identity
          socket: socket.identity
          to: msg.to

        @emit "hangup", req

    else if msg.type is "answer"
      return unless msg.to
      return unless msg.args
      return unless msg.args.accepted?
      return unless socket.identity
      @adapter.getId msg.to, (id) =>
        @server.clients[id]?.send JSON.stringify
          type: "answer"
          from: socket.identity
          args:
            accepted: msg.args.accepted

        req =
          name: socket.identity
          socket: socket.identity
          to: msg.to
          accepted: msg.args.accepted

        @emit "answer", req

    else if msg.type is "candidate"
      return unless msg.to
      return unless msg.args
      return unless msg.args.candidate
      return unless socket.identity
      @adapter.getId msg.to, (id) =>
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
      @adapter.getId msg.to, (id) =>
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
      @adapter.getId msg.to, (id) =>
        @server.clients[id]?.send JSON.stringify
          type: "chat"
          from: socket.identity
          args:
            message: msg.args.message

        req =
          name: socket.identity
          socket: socket.identity
          to: msg.to
          message: msg.args.message

        @emit "chat", req

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
      @emit "unregister", req

module.exports = Server
