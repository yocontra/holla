util = require './util'

if window?
  engineClient = require 'engine.io'
  EventEmitter = require 'emitter'
else 
  engineClient = require 'engine.io-client'
  {EventEmitter} = require 'events'

util.extendSocket engineClient.Socket

getDelay = (a) ->
  if a > 10
    return 15000
  else if a > 5
    return 5000
  else if a > 3
    return 1000
  return 1000

class Client extends EventEmitter
  constructor: (plugin, options={}) ->
    @[k]=v for k,v of plugin
    @options[k]=v for k,v of options
    @options.reconnect ?= true
    @options.reconnectLimit ?= Infinity
    @isServer = false
    @isClient = true
    @isBrowser = window?

    eiopts =
      host: @options.host
      port: @options.port
      secure: @options.secure
      path: "/#{@options.namespace}"
      resource: @options.resource
      transports: @options.transports
      upgrade: @options.upgrade
      flashPath: @options.flashPath
      policyPort: @options.policyPort
      forceJSONP: @options.forceJSONP
      forceBust: @options.forceBust
      debug: @options.debug

    @ssocket = new engineClient eiopts
    @ssocket.parent = @
    @ssocket.once 'open', @handleConnection
    @ssocket.on 'error', @handleError
    @ssocket.on 'message', @handleMessage
    @ssocket.on 'close', @handleClose
    @start()
    return

  # Disconnects socket
  disconnect: -> @ssocket.disconnect(); @

  # Handle connection
  handleConnection: =>
    @emit 'connected'
    @connect @ssocket

  # Handle socket message
  handleMessage: (msg) =>
    @emit 'inbound', @ssocket, msg
    @inbound @ssocket, msg, (formatted) =>
      @validate @ssocket, formatted, (valid) =>
        if valid
          @emit 'message', @ssocket, formatted
          @message @ssocket, formatted
        else
          @emit 'invalid', @ssocket, formatted
          @invalid @ssocket, formatted
    
  # Handle socket error
  handleError: (err) =>
    err = new Error err if typeof err is 'string'
    @error @ssocket, err

  # Handle socket close
  handleClose: (reason) =>
    return if @ssocket.reconnecting
    if @options.reconnect
      @reconnect (err) =>
        return unless err?
        @emit 'close', @ssocket, reason
        @close @ssocket, reason
    else
      @emit 'close', @ssocket, reason
      @close @ssocket, reason

  reconnect: (cb) =>
    return cb "Already reconnecting" if @ssocket.reconnecting
    @ssocket.reconnecting = true
    @ssocket.disconnect() if @ssocket.readyState is 'open'
    maxAttempts = @options.reconnectLimit
    attempts = 0

    done = =>
      @ssocket.reconnecting = false
      cb()

    err = (e) =>
      @ssocket.reconnecting = false
      cb e

    @ssocket.once 'open', done
    #@ssocket.once 'error', err

    connect = =>
      return unless @ssocket.reconnecting # already done
      return err "Exceeded max attempts" if attempts >= maxAttempts
      # keep trying
      attempts++
      @ssocket.open()

      setTimeout connect, getDelay attempts
    setTimeout connect, getDelay attempts

module.exports = Client