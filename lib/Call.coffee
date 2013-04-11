shims = require './shims'
Emitter = require 'emitter'

class User extends Emitter
  constructor: (@call, @name) ->

class Call extends Emitter
  constructor: (@client, @id, @isCaller=false) ->
    @client.io.on "#{@id}:userAdded", @addUser

  _addUser: (name) =>
    @users[name] = new User @call, name
    return @

  answer: =>
    @client.io.emit "#{@id}:callResponse", true
    return @

  decline: =>
    @client.io.emit "#{@id}:callResponse", false
    return @

  add: (name, cb) =>
    @client.io.emit "addUser", @id, name, cb
    return @

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

module.exports = Call