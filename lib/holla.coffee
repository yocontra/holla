{EventEmitter} = eio
PeerConnection = window.PeerConnection or window.webkitPeerConnection00 or window.webkitRTCPeerConnection
IceCandidate = window.RTCIceCandidate
SessionDescription = window.RTCSessionDescription
URL = window.URL or window.webkitURL or window.msURL or window.oURL
getUserMedia = navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.mozGetUserMedia or navigator.msGetUserMedia

class RTC extends EventEmitter
  constructor: (opts={}) ->
    opts.host ?= window.location.hostname
    opts.port ?= (if window.location.port.length > 0 then parseInt window.location.port else 80)
    opts.secure ?= (window.location.protocol is 'https:')
    opts.path ?= "/holla"

    @socket = new eio.Socket opts
    @socket.on "open", @emit.bind "connected"
    @socket.on "close", @emit.bind "disconnected"
    @socket.on "error", @emit.bind "error"
    @socket.on "message", (msg) =>
      msg = JSON.parse msg
      if msg.type is "presence"
        @emit "presence", msg.args
        @emit "presence.#{msg.args.name}", msg.args.online
        return
      return unless msg.type is "offer"
      c = new Call @, msg.from, false
      @emit "call", c
      return

  register: (name, cb) ->
    @socket.send JSON.stringify
      type: "register"
      args:
        name: name

    handle = (msg) =>
      msg = JSON.parse msg
      return unless msg.type is "register"
      @socket.removeListener "message", handle
      if msg.args.result is true
        @user = name
        @authorized = true
        @emit "authorized"
      cb? msg.args.result
    @socket.on "message", handle

  call: (user) -> new Call @, user, true

  ready: (fn) ->
    if @authorized
      fn()
    else
      @once 'authorized', fn

class Call extends EventEmitter
  constructor: (@parent, @user, @isCaller) ->
    @startTime = new Date
    @socket = @parent.socket

    @pc = @createConnection()
    if @isCaller
      @socket.send JSON.stringify
        type: "offer"
        to: @user
    @emit "calling"
    @socket.on "message", @handleMessage

  createConnection: ->
    pc = new PeerConnection holla.config
    pc.onconnecting = =>
      @emit 'connecting'
      return
    pc.onopen = =>
      @emit 'connected'
      return
    pc.onicecandidate = (evt) =>
      if evt.candidate
        @socket.send JSON.stringify
          type: "candidate"
          to: @user
          args:
            candidate: evt.candidate
      return

    pc.onaddstream = (evt) =>
      @remoteStream = evt.stream
      @_ready = true
      @emit "ready", @remoteStream
      return
    pc.onremovestream = (evt) =>
      console.log evt
      return

    return pc

  handleMessage: (msg) =>
    msg = JSON.parse msg
    return unless msg.from is @user
    if msg.type is "answer"
      return @emit "rejected" unless msg.args.accepted
      @emit "answered"
      @initSDP()
    else if msg.type is "candidate"
      @pc.addIceCandidate new IceCandidate msg.args.candidate
    else if msg.type is "sdp"
      @pc.setRemoteDescription new SessionDescription msg.args
      @emit "sdp"
    else if msg.type is "hangup"
      @emit "hangup"
    else if msg.type is "chat"
      @emit "chat", msg.args.message
    return

  addStream: (s) -> 
    @pc.addStream s
    return @

  ready: (fn) ->
    if @_ready
      fn @remoteStream
    else
      @once 'ready', fn
    return @

  duration: ->
    s = @endTime.getTime() if @endTime?
    s ?= Date.now()
    e = @startTime.getTime()
    return (s-e)/1000

  chat: (msg) ->
    @socket.send JSON.stringify
      type: "chat"
      to: @user
      args:
        message: msg
    return @

  answer: ->
    @startTime = new Date
    @socket.send JSON.stringify
      type: "answer"
      to: @user
      args:
        accepted: true
    @initSDP()
    return @

  decline: ->
    @socket.send JSON.stringify
      type: "answer"
      to: @user
      args:
        accepted: false
    return @

  end: ->
    @endTime = new Date
    @pc.close()
    @socket.send JSON.stringify
      type: "hangup"
      to: @user
    @emit "hangup"
    return @

  initSDP: ->
    done = (desc) =>
      @pc.setLocalDescription desc
      @socket.send JSON.stringify
        type: "sdp"
        to: @user
        args: desc

    err = (e) -> console.log e

    return @pc.createOffer done, err if @isCaller
    return @pc.createAnswer done, err if @pc.remoteDescription
    @once "sdp", =>
      @pc.createAnswer done, err


holla =
  Call: Call
  RTC: RTC
  supported: PeerConnection? and getUserMedia?
  connect: (host) -> new RTC host
  config:
    iceServers: [url: "stun:stun.l.google.com:19302"]

  streamToBlob: (s) -> URL.createObjectURL s
  pipe: (stream, el) ->
    uri = holla.streamToBlob stream
    if typeof el is "string"
      document.getElementById(el).src
    else if el.jquery
      el.attr 'src', uri
    else
      el.src = uri
    return holla

  createStream: (opt, cb) ->
    return cb "Missing getUserMedia" unless getUserMedia?
    err = cb
    succ = (s) -> cb null, s
    getUserMedia.call navigator, opt, succ, err
    return holla

  createFullStream: (cb) -> holla.createStream {video:true,audio:true}, cb
  createVideoStream: (cb) -> holla.createStream {video:true,audio:false}, cb
  createAudioStream: (cb) -> holla.createStream {video:true,audio:false}, cb

window.holla = holla