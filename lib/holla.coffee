{EventEmitter} = eio
PeerConnection = window.PeerConnection or window.webkitPeerConnection00 or window.webkitRTCPeerConnection
URL = window.URL or window.webkitURL or window.msURL or window.oURL
getUserMedia = navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.mozGetUserMedia or navigator.msGetUserMedia

###

Client A sends

type: "offer"
to: "B"
args: null

------

Client B gets

type: "offer"
from: "wat"
args: null

------

Client B sends

type: "answer"
to: "B"
args:
  accepted: true

------

Client A gets ICECAND

type: "candidate"
to: "B"
args:
  candidate: "wat"

------

Client B gets ICECAND

type: "candidate"
to: "A"
args: 
  candidate: "wat"

------

Client A sends

type: "sdp"
to: "B"
args:
  description: "wat"

------

Client B sends

type: "sdp"
to: "A"
args:
  description: "wat"
------


###

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
      return unless msg.type is "offer"
      c = new Call @, msg.from, false
      @emit "call", c
      return

  identify: (name, cb) ->
    @socket.send JSON.stringify
      type: "identify"
      args:
        name: name

    handle = (msg) =>
      msg = JSON.parse msg
      return unless msg.type is "identify"
      @socket.removeListener "message", handle
      cb msg.args.result
    @socket.on "message", handle

  call: (user) -> new Call @, user, true

class Call extends EventEmitter
  constructor: (@parent, @user, @isCaller) ->
    @startTime = new Date Date.now()
    @socket = @parent.socket

    @pc = new PeerConnection holla.config

    @pc.onconnecting = =>
      console.log "connecting"
      @emit 'connecting'
    @pc.onopen = =>
      console.log "connected"
      @emit 'connected'
    @pc.onicecandidate = (evt) =>
      @_candidate = evt.candidate
      console.log evt
      @emit "ICEcandidate", evt.candidate

    @pc.onaddstream = (evt) ->
      @remoteStream = evt.stream
      @_ready = true
      @emit "ready", @remoteStream

    if @isCaller
      @socket.send JSON.stringify
        type: "offer"
        to: @user

    @emit "calling"
    @socket.on "message", @handleMessage

  handleMessage: (msg) =>
    msg = JSON.parse msg
    console.log @user, msg
    return unless msg.from is @user # not us
    if msg.type is "answer" # step 1
      # caller gets answer and sends ICE
      return @emit "rejected" unless msg.args.accepted
      @emit "answered"
      @initICE()
    else if msg.type is "candidate" # step 2
      @pc.addIceCandidate new RTCIceCandidate msg.args.candidate
      @initSDP()
    else if msg.type is "sdp" # step 3
      @pc.setRemoteDescription new RTCSessionDescription msg.args.description
    else if msg.type is "hangup"
      @emit "hangup"
      # TODO: stuff

  connections: []
  addStream: (s) -> @pc.addStream s

  ready: (fn) ->
    if @_ready
      fn @remoteStream
    else
      @once 'ready', fn

  duration: ->
    s = @endTime.getTime() if @endTime?
    s ?= Date.now()
    e = @startTime.getTime()
    return (s-e)/1000

  answer: ->
    @socket.send JSON.stringify
      type: "answer"
      to: @user
      args:
        accepted: true
    @initICE()

  decline: ->
    @socket.send JSON.stringify
      type: "answer"
      to: @user
      args:
        accepted: false

  end: ->
    @endTime = Date.now()
    return @

  initICE: ->
    send = (candidate) =>
      @socket.send JSON.stringify
        type: "candidate"
        to: @user
        args:
          candidate: candidate
    if @_candidate
      send @_candidate
    else
      @on "ICEcandidate", send

  initSDP: ->
    done = (desc) =>
      @pc.setLocalDescription desc
      @socket.send JSON.stringify
        type: "sdp"
        to: @user
        args: desc
    if @isCaller
      @pc.createOffer done
    else
      @pc.createAnswer @pc.remoteDescription, done



holla =
  Call: Call
  RTC: RTC
  connect: (host) -> new RTC host
  config:
    iceServers: [
      url: "stun:stun.l.google.com:19302"
    ]

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

  createFullStream: (cb) ->
    holla.createStream {video:true,audio:true}, cb

window.holla = holla