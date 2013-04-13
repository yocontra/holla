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

class Call extends Emitter
  constructor: (@client, @id, callerName) ->
    @_users = {}
    if callerName
      @_add callerName
      @caller = @user callerName

    @client.io.on "#{@id}:userAdded", (name) =>
      @_add name
      user = @user name
      console.log "userAdded", user
      user.createConnection()
      user.addLocalStream @localStream
      user.sendOffer()

  answer: =>
    throw new Error "Must call setLocalStream first" unless @localStream
    @client.io.emit "#{@id}:callResponse", true
    @client.emit "callAnswered", @
    @caller.createConnection()
    @caller.addLocalStream @localStream
    @caller.once "sdp", @caller.sendAnswer
    return @

  decline: =>
    @client.io.emit "#{@id}:callResponse", false
    @client.emit "callDeclined", @
    return @

  _add: (name) =>
    @_users[name] ?= new User @, name
    return @

  add: (name) =>
    throw new Error "Must call setLocalStream first" unless @localStream
    @_add name
    @client.io.emit "addUser", @id, name, @_handleUserResponse @user name
    return @user name

  user: (name) -> @_users[name]
  users: (name) -> @_users

  setLocalStream: (stream) =>
    @localStream = stream
    return @

  releaseLocalStream: =>
    @localStream.stop()
    delete @localStream
    return @

  mute: =>
    throw new Error "Must call setLocalStream first" unless @localStream
    track.enabled = false for track in @localStream.getAudioTracks()
    return @
  
  unmute: =>
    throw new Error "Must call setLocalStream first" unless @localStream
    track.enabled = true for track in @localStream.getAudioTracks()
    return @

  _handleUserResponse: (user) => (err) =>
    if err?
      if err is "Call declined"
        user.accepted = false
        user.emit "declined"
        @emit "userDeclined", user
      else
        user.emit "error", err
        @emit "error", err
    else
      user.accepted = true
      user.emit "answered"
      @emit "userAnswered", user

module.exports = Call