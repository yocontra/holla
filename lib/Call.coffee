User = require './User'
Emitter = require 'emitter'

class Call extends Emitter
  constructor: (@client, @id, callerName) ->
    @_users = {}
    if callerName
      @_add callerName
      @caller = @user callerName

    @client.io.on "#{@id}:end", => @emit "end"
    @client.io.on "#{@id}:userAdded", (name) =>
      @_add name
      user = @user name
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
    @localStream?.stop()
    delete @localStream
    return @

  end: (releaseStream) =>
    @client.io.emit "endCall", @id, (err) =>
      @emit "error", err if err?
      @releaseLocalStream() if releaseStream
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
    return @

  _add: (name) =>
    @_users[name] ?= new User @, name
    return @

module.exports = Call