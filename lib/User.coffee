shims = require './shims'
Emitter = require 'emitter'

class User extends Emitter
  connection: null
  constructor: (@call, @name) ->
    @createConnection()
    @call.client.io.on "#{call.id}:#{name}:sdp", @_handleRemoteSDP
    @call.client.io.on "#{call.id}:#{name}:candidate", @_handleRemoteCandidate

  createConnection: ->
    @connection = new shims.PeerConnection shims.PeerConnConfig, shims.constraints
    @connection.onconnecting = => @emit "connecting"
    @connection.onopen = => @emit "connected"
    @connection.onicecandidate = (evt) =>
      @sendCandidate evt.candidate if evt?.candidate?
    @connection.onaddstream = (evt) => @addStream evt.stream
    @connection.onremovestream = (evt) => @removeStream()
    return @

  addLocalStream: (stream) ->
    @connection.addStream stream
    return @

  addStream: (stream) ->
    @_ready = true
    @stream = stream
    @emit "ready", @stream
    return @

  removeStream: ->
    @end()
    return @

  ready: (fn) ->
    if @_ready
      fn @stream
    else
      @once 'ready', fn
    return @

  sendCandidate: (candidate) ->
    @call.client.io.emit "sendCandidate", @call.id, @name, candidate, @_handleError
  
  sendOffer: ->
    done = (desc) =>
      @connection.setLocalDescription desc
      desc.sdp = shims.processSDPOut desc.sdp
      @call.client.io.emit "sendSDPOffer", @call.id, @name, desc, @_handleError

    err = (e) => @emit "error", e
    @connection.createOffer done, err, shims.constraints
    return @

  sendAnswer: ->
    done = (desc) =>
      desc.sdp = shims.processSDPOut desc.sdp
      @connection.setLocalDescription desc
      @call.client.io.emit "sendSDPAnswer", @call.id, @name, desc, @_handleError

    @connection.createAnswer done, @_handleError, shims.constraints
    return @

  _handleError: (e) => @emit "error", e if e?
  _handleRemoteSDP: (desc) =>
    desc.sdp = shims.processSDPIn desc.sdp
    succ = => @emit "sdp"
    @connection.setRemoteDescription new shims.SessionDescription(desc), succ, @_handleError
    return @
  _handleRemoteCandidate: (candidate) =>
    @emit "candidate", candidate
    @connection.addIceCandidate new shims.IceCandidate candidate
    return @

module.exports = User