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

module.exports =
  options:
    namespace: 'holla'
    resource: 'default'
    presence: true
    debug: false

  start: ->
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
        @server.clients[id]?.write
          type: "presence"
          args:
            name: preq.name
            online: preq.online
      return

  validate: (socket, msg, done) ->
    if @options.debug
      console.log socket.id, socket.identity, msg
    return done false unless typeof msg is 'object'
    return done false unless typeof msg.type is 'string'
    if msg.type is "register"
      return done false unless typeof msg.args is 'object'
      return done false unless typeof msg.args.name is 'string'
    else if msg.type is "offer"
      return done false unless typeof msg.to is 'string'
      return done false unless socket.identity
    else if msg.type is "hangup"
      return done false unless typeof msg.to is 'string'
      return done false unless socket.identity
    else if msg.type is "answer"
      return done false unless typeof msg.to is 'string'
      return done false unless socket.identity
      return done false unless typeof msg.args is 'object'
      return done false unless typeof msg.args.accepted is 'boolean'
    else if msg.type is "candidate"
      return done false unless typeof msg.to is 'string'
      return done false unless socket.identity
      return done false unless typeof msg.args is 'object'
      return done false unless typeof msg.args.candidate is 'object'
    else if msg.type is "sdp"
      return done false unless typeof msg.to is 'string'
      return done false unless socket.identity
      return done false unless typeof msg.args is 'object'
      return done false unless msg.args.sdp
      return done false unless msg.args.type
    else if msg.type is "chat"
      return done false unless typeof msg.to is 'string'
      return done false unless socket.identity
      return done false unless typeof msg.args is 'object'
      return done false unless typeof msg.args.message is 'string'
    else
      return done false
    return done true
    
  close: (socket, reason) ->
    req =
      name: socket.identity
      reason: reason
      socket: socket

    @emit "close", req
    @adapter.unregister req, =>
      @emit "unregister", req

  invalid: (socket, msg) -> socket.close()
  error: (socket, msg) -> socket.close()

  message: (socket, msg) ->
    switch msg.type
      when "register"
        req =
          name: msg.args.name
          socket: socket
        @adapter.register req, (err) =>
          unless err?
            socket.identity ?= msg.args.name
            @emit "register", req
          socket.write
            type: "register"
            args:
              result: !err

      when "offer"
        @adapter.getId msg.to, (id) =>
          return unless @server.clients[id]?
          @server.clients[id].write
            type: "offer"
            from: socket.identity

          req =
            name: socket.identity
            socket: socket
            to: msg.to

          @emit "offer", req

      when "hangup"
        @adapter.getId msg.to, (id) =>
          return unless @server.clients[id]?
          @server.clients[id].write
            type: "hangup"
            from: socket.identity

          req =
            name: socket.identity
            socket: socket
            to: msg.to

          @emit "hangup", req

      when "answer"
        @adapter.getId msg.to, (id) =>
          return unless @server.clients[id]?
          @server.clients[id].write
            type: "answer"
            from: socket.identity
            args:
              accepted: msg.args.accepted

          req =
            name: socket.identity
            socket: socket
            to: msg.to
            args:
              accepted: msg.args.accepted

          @emit "answer", req

      when "candidate"
        @adapter.getId msg.to, (id) =>
          return unless @server.clients[id]?
          @server.clients[id].write
            type: "candidate"
            from: socket.identity
            args:
              candidate: msg.args.candidate

      when "sdp"
        @adapter.getId msg.to, (id) =>
          return unless @server.clients[id]?
          @server.clients[id].write
            type: "sdp"
            from: socket.identity
            args:
              sdp: msg.args.sdp
              type: msg.args.type

      when "chat"
        @adapter.getId msg.to, (id) =>
          return unless @server.clients[id]?
          @server.clients[id].write
            type: "chat"
            from: socket.identity
            args:
              message: msg.args.message

          req =
            name: socket.identity
            socket: socket
            to: msg.to
            message: msg.args.message

          @emit "chat", req