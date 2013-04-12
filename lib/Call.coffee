shims = require './shims'
Emitter = require 'emitter'

class User extends Emitter
  constructor: (@call, @name) ->

  ready: (fn) ->

class Call extends Emitter
  constructor: (@client, @id, callerName) ->
    @_users = {}
    if callerName
      @caller = new User @, callerName
      @_users[callerName] = @caller

  answer: =>
    @client.io.emit "#{@id}:callResponse", true
    @client.emit "callAnswered", @
    return @

  decline: =>
    @client.io.emit "#{@id}:callResponse", false
    @client.emit "callDeclined", @
    return @

  add: (name) =>
    newUser = new User @, name
    @_users[name] = newUser
    @client.io.emit "addUser", @id, name, @_handleUserResponse(newUser)

    return @_users[name]

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
    return @ unless @localStream
    track.enabled = false for track in @localStream.getAudioTracks()
    return @
  
  unmute: =>
    return @ unless @localStream
    track.enabled = true for track in @localStream.getAudioTracks()
    return @

  _handleUserResponse: (user) => (err) =>
    if err?
      if err is "Call declined"
        user.accepted = false
        user.emit "declined"
        @emit "userDeclined", @_users[name]
      else
        user.emit "error", err
        @emit "error", err
    else
      user.accepted = true
      user.emit "answered"

module.exports = Call