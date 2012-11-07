util = require './util'
isBrowser = util.isBrowser()

if isBrowser
  engineClient = require 'node_modules/engine.io-client/lib/engine.io-client'
  {EventEmitter} = engineClient
else 
  engineClient = require 'engine.io-client'
  {EventEmitter} = require 'events'

util.extendSocket engineClient.Socket

class Client extends EventEmitter
  constructor: (plugin) ->
    @[k]=v for k,v of plugin
    @isServer = false
    @isClient = true
    @isBrowser = isBrowser

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

    @ssocket = new engineClient.Socket eiopts
    @ssocket.parent = @
    @ssocket.on 'open', @handleConnection
    @ssocket.on 'error', @handleError
    @ssocket.on 'message', @handleMessage
    @ssocket.on 'close', @handleClose
    @start()
    return

  # Disconnects socket
  disconnect: -> @ssocket.close(); @

  # Handle connection
  handleConnection: =>
    @connected = true
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
    @emit 'close', @ssocket, reason   
    @close @ssocket, reason
    ###
    @reconnect (worked) =>
      return if worked
      @emit 'close', @ssocket, reason
      @close @ssocket, reason
    ###
  ###
  reconnect: (cb) =>
    attempts = 0
    connect = =>
      ++attempts
      return cb false if attempts is 10
  ###

module.exports = Client