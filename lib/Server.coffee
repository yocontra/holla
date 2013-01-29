{EventEmitter} = require 'events'
engineServer = require 'engine.io'

class Server extends EventEmitter
  constructor: (@httpServer, @options={}) ->
    @options.path ?= "/holla"
    @options.destroyUpgrade ?= false
    @server = engineServer.attach @httpServer, @options
    @server.httpServer = @httpServer
    @server.on 'connection', @handleConnection

  presence: (user, presence, users) ->
    for id in users
      @server.clients[id]?.send JSON.stringify
        type: "presence"
        args:
          name: user
          online: presence.online
    return

  handleConnection: (socket) =>
    socket.on 'message', (msg) =>
      console.log socket.id, msg
      try
        msg = JSON.parse msg
      catch e
        return
      return unless msg.type and typeof msg.type is "string"
      return if msg.args and typeof msg.args isnt "object"

      if msg.type is "identify"
        return unless msg.args
        return unless msg.args.name
        req =
          name: msg.args.name
          socket: socket
        @identify req, (res=true) ->
          socket.identity = msg.args.name if res?
          socket.send JSON.stringify
            type: "identify"
            args:
              result: res

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

      
      
    socket.on 'error', (err) =>
      req =
        name: socket.identity
        reason: err
        socket: socket
      @error? req

    socket.on 'close', (reason) =>
      req =
        name: socket.identity
        reason: reason
        socket: socket

      @close? req

module.exports = Server
