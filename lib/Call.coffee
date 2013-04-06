shims = require './shims'

EventEmitter = require 'emitter'

class Call extends EventEmitter
  constructor: (@parent, @user, @isCaller) ->
    @startTime = new Date
    @socket = @parent.ssocket

    @pc = @createConnection()
    if @isCaller
      @socket.write
        type: "offer"
        to: @user
    @emit "calling"

    @parent.on "answer.#{@user}", (accepted) =>
      return @emit "rejected" unless accepted
      @emit "answered"
      if @isCaller
        @initSDP()

    @parent.on "candidate.#{@user}", (candidate) =>
      @pc.addIceCandidate new shims.IceCandidate candidate

    @parent.on "sdp.#{@user}", @processRemoteSDP

    @parent.on "hangup.#{@user}", =>
      @emit "hangup"

    @parent.on "chat.#{@user}", (msg) =>
      @emit "chat", msg

  processRemoteSDP: (desc) =>
    return if @pc.remoteDescription
    console.log "#{@isCaller} remote", desc
    desc.sdp = shims.processSDPIn desc.sdp
    err = (e) -> throw e
    succ = =>
      @emit "sdp"
      @initSDP() unless @isCaller
    @pc.setRemoteDescription new shims.SessionDescription(desc), succ, err

  createConnection: =>
    pc = new shims.PeerConnection shims.PeerConnConfig, shims.constraints
    pc.onconnecting = =>
      @emit 'connecting'
      return
    pc.onopen = =>
      @emit 'connected'
      return
    pc.onicecandidate = (evt) =>
      if evt.candidate
        @socket.write
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
      console.log "removestream", evt
      @end()
      @emit 'hangup'
      return

    return pc

  addStream: (s) =>
    @localStream = s
    @pc.addStream s
    return @

  ready: (fn) =>
    if @_ready
      fn @remoteStream
    else
      @once 'ready', fn
    return @

  duration: =>
    s = @endTime.getTime() if @endTime?
    s ?= Date.now()
    e = @startTime.getTime()
    return (s-e)/1000

  chat: (msg) =>
    @parent.chat @user, msg
    return @

  answer: =>
    @startTime = new Date
    @socket.write
      type: "answer"
      to: @user
      args:
        accepted: true
    return @

  decline: =>
    @socket.write
      type: "answer"
      to: @user
      args:
        accepted: false
    return @

  releaseStream: =>
    @localStream.stop()

  end: =>
    @endTime = new Date
    try
      @pc.close()
    @socket.write
      type: "hangup"
      to: @user
    @emit "hangup"
    return @

  mute: =>
    track.enabled = false for track in @localStream.getAudioTracks()
  
  unmute: =>
    track.enabled = true for track in @localStream.getAudioTracks()

  initSDP: =>
    done = (desc) =>
      desc.sdp = shims.processSDPOut desc.sdp
      console.log "#{@isCaller} local", desc

      @pc.setLocalDescription desc

      @socket.write
        type: "sdp"
        to: @user
        args: desc

    err = (e) -> throw e
    if @isCaller
      return @pc.createOffer done, err, shims.constraints
    
    if @pc.remoteDescription
      @pc.createAnswer done, err, shims.constraints
    else
      @once "sdp", =>
        @pc.createAnswer done, err, shims.constraints

module.exports = Call