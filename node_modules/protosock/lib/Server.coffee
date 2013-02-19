util = require './util'
engineServer = require 'engine.io'
util.extendSocket engineServer.Socket
{EventEmitter} = require 'events'

class Server extends EventEmitter
  constructor: (@httpServer, plugin, options={}) ->
    @[k]=v for k,v of plugin
    @options[k]=v for k,v of options
    @isServer = true
    @isClient = false
    @isBrowser = false
    throw 'httpServer required' unless @httpServer?

    eiopts =
      path: "/#{@options.namespace}"
      resource: @options.resource
      transports: @options.transports
      cookie: @options.cookie
      policyFile: @options.policyFile
      allowUpgrades: @options.upgrades?.allow
      destroyUpgrade: false
      pingTimeout: @options.ping?.timeout
      pingInterval: @options.ping?.interval
      debug: @options.debug

    @server = engineServer.attach @httpServer, eiopts
    @server.httpServer = @httpServer
    @server.on 'connection', @handleConnection
    @start()

  # Closes HTTP server
  # TODO: close websocket handlers without closing http
  destroy: => @server.httpServer.close(); @

  # Disconnects all clients
  disconnect: => @server.close(); @

  # Handle connection
  handleConnection: (socket) =>
    socket.parent = @
    socket.on 'message', (msg) => @handleMessage socket, msg
    socket.on 'error', (err) => @handleError socket, err
    socket.on 'close', (reason) => @handleClose socket, reason
    @connect socket

  # Handle socket message
  handleMessage: (socket, msg) =>
    @emit 'inbound', socket, msg
    @inbound socket, msg, (formatted) =>
      @validate socket, formatted, (valid) =>
        if valid
          @emit 'message', socket, formatted
          @message socket, formatted
        else
          @emit 'invalid', socket, formatted
          @invalid socket, formatted
    
  # Handle socket error
  handleError: (socket, err) =>
    err = new Error err if typeof err is 'string'
    @error socket, err

  # Handle socket close
  handleClose: (socket, reason) =>
    @emit 'close', socket, reason
    @close socket, reason

module.exports = Server