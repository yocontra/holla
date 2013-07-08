shims = require './shims'
Emitter = require 'emitter'
Channel = require './Channel'

class User extends Emitter
  connection: null
  constructor: (@call, @name) ->
    @createConnection()
    @call.client.io.on "#{call.id}:#{name}:sdp", @_handleRemoteSDP
    @call.client.io.on "#{call.id}:#{name}:candidate", @_handleRemoteCandidate

  createConnection: ->
    @channels = {}
    @connection = new shims.PeerConnection shims.PeerConnConfig, shims.constraints
    @connection.onconnecting = => @emit "connecting"
    @connection.onopen = => @emit "connected"
    @connection.onicecandidate = (evt) =>
      @sendCandidate evt.candidate if evt?.candidate?
    @connection.onaddstream = (evt) => @addStream evt.stream
    @connection.onremovestream = (evt) => @removeStream()
    @connection.oniceconnectionstatechange = @connection.onicechange = =>
      if @connection.iceConnectionState is 'disconnected'
        @closeConnection()

    @connection.ondatachannel = (evt) =>
      chan = evt.channel
      @channels[chan.label] = new Channel(@connection, chan.label).setChannel chan
      @emit 'data:#{chan.label}', @channels[chan.label]
    return @

  closeConnection: ->
    return @ unless @connection?
    for name, chan of @channels
      chan.end()
    @connection.close()
    @connection = null
    @channels = null
    @emit 'disconnected'
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
    @closeConnection()
    return @

  ready: (fn) ->
    if @_ready
      fn @stream
    else
      @once 'ready', fn
    return @

  channel: (name) ->
    unless @channels[name]?
      @channels[name] = new Channel @connection, name
      @emit 'data:#{name}', @channels[name]
    return @channels[name]

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