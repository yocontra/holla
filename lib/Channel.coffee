Emitter = require 'emitter'

class Channel extends Emitter
  open: false
  constructor: (@connection, @name) ->
    @options =
      reliable: false

  setChannel: (chan) =>
    @dc = chan
    @dc.onopen = =>
      @open = true
      @emit 'open'
    @dc.onclose = =>
      @open = false
      @emit 'end'
    @dc.onmessage = (e) =>
      @emit 'data', JSON.parse e.data
    return @

  connect: =>
    @setChannel @connection.createDataChannel @name, @options
    return @

  send: (data) =>
    @dc.send JSON.stringify data if @open
    return @

  end: =>
    @dc.close() if @open
    return @

module.exports = Channel