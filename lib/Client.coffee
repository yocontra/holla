Emitter = require 'emitter'
socketio = io #require 'socket.io-client'
Call = require './Call'

class Client extends Emitter
  constructor: (@options={}) ->
    @io = socketio.connect @options.host, @options.socketio
    @io.on 'reconnect', => @emit 'reconnect'
    @io.on 'disconnect', => @emit 'disconnect'
    @io.on 'error', (err) => @emit 'error', err
    @io.on 'callRequest', (callInfo) =>
      call = new Call @, callInfo.id, callInfo.caller
      @emit "call", call

    @io.on 'presenceChange', (user, status) =>
      @emit 'presence', user, status

  createCall: (cb) ->
    @io.emit 'createCall', (err, id) =>
      return cb err if err?
      call = new Call @, id
      cb null, call
    return @

  register: (name, cb) ->
    @io.emit 'register', name, cb

  unregister: (cb) ->
    @io.emit 'unregister', cb

module.exports = Client