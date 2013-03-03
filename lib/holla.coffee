Call = require './Call'
shims = require './shims'
ProtoSock = require 'protosock'

client =
  options:
    namespace: 'holla'
    resource: 'default'
    debug: false

  register: (name, cb) ->
    @ssocket.write
      type: "register"
      args:
        name: name

    @once "register", (worked) =>
      if worked
        @user = name
        @emit "authorized"
      @authorized = worked
      cb? worked

  call: (user) -> new Call @, user, true
  chat: (user, msg) ->
    @ssocket.write
      type: "chat"
      to: user
      args:
        message: msg
    return @

  ready: (fn) ->
    if @authorized
      fn()
    else
      @once 'authorized', fn
    return @

  validate: (socket, msg, done) ->
    if @options.debug
      console.log msg
    return done false unless typeof msg is 'object'
    return done false unless typeof msg.type is 'string'
    if msg.type is "register"
      return done false unless typeof msg.args is 'object'
      return done false unless typeof msg.args.result is 'boolean'
    else if msg.type is "offer"
      return done false unless typeof msg.from is 'string'
    else if msg.type is "answer"
      return done false unless typeof msg.args is 'object'
      return done false unless typeof msg.from is 'string'
      return done false unless typeof msg.args.accepted is 'boolean'
    else if msg.type is "sdp"
      return done false unless typeof msg.args is 'object'
      return done false unless typeof msg.from is 'string'
      return done false unless msg.args.sdp
      return done false unless msg.args.type
    else if msg.type is "candidate"
      return done false unless typeof msg.args is 'object'
      return done false unless typeof msg.from is 'string'
      return done false unless typeof msg.args.candidate is 'object'
    else if msg.type is "chat"
      return done false unless typeof msg.args is 'object'
      return done false unless typeof msg.from is 'string'
      return done false unless typeof msg.args.message is 'string'
    else if msg.type is "hangup"
      return done false unless typeof msg.from is 'string'
    else if msg.type is "presence"
      return done false unless typeof msg.args is 'object'
      return done false unless typeof msg.args.name is 'string'
      return done false unless typeof msg.args.online is 'boolean'
    else
      return done false
    return done true

  error: (socket, err) -> @emit 'error', err, socket
  message: (socket, msg) ->
    switch msg.type
      when "register"
        @emit "register", msg.args.result

      when "offer"
        c = new Call @, msg.from, false
        @emit "call", c

      when "presence"
        @emit "presence", msg.args
        @emit "presence.#{msg.args.name}", msg.args.online

      when "chat"
        @emit "chat", {from: msg.from, message: msg.args.message}
        @emit "chat.#{msg.from}", msg.args.message

      when "hangup"
        @emit "hangup", {from: msg.from}
        @emit "hangup.#{msg.from}"

      when "answer"
        @emit "answer", {from: msg.from, accepted: msg.args.accepted}
        @emit "answer.#{msg.from}", msg.args.accepted

      when "candidate"
        @emit "candidate", {from: msg.from, candidate: msg.args.candidate}
        @emit "candidate.#{msg.from}", msg.args.candidate

      when "sdp"
        @emit "sdp", {from: msg.from, sdp: msg.args.sdp, type: msg.args.type}
        @emit "sdp.#{msg.from}", msg.args


holla =
  createClient: ProtoSock.createClientWrapper client
  Call: Call
  supported: shims.supported
  config: shims.PeerConnConfig
  streamToBlob: (s) -> shims.URL.createObjectURL s
  pipe: (stream, el) ->
    uri = holla.streamToBlob stream
    shims.attachStream uri, el

  record: shims.recordVideo
  
  createStream: (opt, cb) ->
    return cb "Missing getUserMedia" unless shims.getUserMedia?
    err = cb
    succ = (s) -> cb null, s
    shims.getUserMedia opt, succ, err
    return holla

  createFullStream: (cb) -> holla.createStream {video:true,audio:true}, cb
  createVideoStream: (cb) -> holla.createStream {video:true,audio:false}, cb
  createAudioStream: (cb) -> holla.createStream {video:false,audio:true}, cb

module.exports = holla