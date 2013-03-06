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
      @initSDP()

    @parent.on "candidate.#{@user}", (candidate) =>
      @pc.addIceCandidate new shims.IceCandidate candidate

    @parent.on "sdp.#{@user}", (desc) =>
      desc.sdp = shims.processSDPIn desc.sdp
      err = (e) -> throw e
      succ = =>
        @initSDP() unless @isCaller
        @emit "sdp"
      @pc.setRemoteDescription new shims.SessionDescription(desc), succ, err

    @parent.on "hangup.#{@user}", =>
      @emit "hangup"

    @parent.on "chat.#{@user}", (msg) =>
      @emit "chat", msg

  createConnection: ->
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
      return

    return pc

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
    @parent.chat @user, msg
    return @

  answer: ->
    @startTime = new Date
    @socket.write
      type: "answer"
      to: @user
      args:
        accepted: true
    return @

  decline: ->
    @socket.write
      type: "answer"
      to: @user
      args:
        accepted: false
    return @

  end: ->
    @endTime = new Date
    try
      @pc.close()
    @socket.write
      type: "hangup"
      to: @user
    @emit "hangup"
    return @

  initSDP: ->
    done = (desc) =>
      desc.sdp = shims.processSDPOut desc.sdp
      @pc.setLocalDescription desc
      @socket.write
        type: "sdp"
        to: @user
        args: desc

    err = (e) -> throw e

    return @pc.createOffer done, err, shims.constraints if @isCaller
    return @pc.createAnswer done, err, shims.constraints if @pc.remoteDescription
    @once "sdp", =>
      @pc.createAnswer done, err

module.exports = Call