class ServerError extends Error
  name: "ServerError"
  constructor: ({@message, @type, @stack}) ->

class Vein
  constructor: (@options={}) ->
    @options.host ?= window.location.hostname
    @options.port ?= (if window.location.port.length > 0 then parseInt window.location.port else 80)
    @options.secure ?= (window.location.protocol is 'https:')
    @options.path ?= '/vein'
    @options.forceBust ?= true

    @socket = new eio.Socket @options
    @socket.on 'open', @handleOpen
    @socket.on 'error', @handleError
    @socket.on 'message', @handleMessage
    @socket.on 'close', @handleClose
    return

  connected: null
  services: null
  _ready: []
  _close: []
  callbacks: {}
  subscribe: {}

  cookie: AIOCookie

  ready: (cb) ->
    @_ready.push cb
    cb @services if @connected is true
    return

  close: (cb) -> 
    @_close.push cb
    cb() if @connected is false
    return

  # Event handlers
  handleOpen: =>
    @getSender('list') (services) =>
      for service in services
        @[service] = @getSender service
        @subscribe[service] = @getSubscriber service
      @services = services
      @connected = true
      cb services for cb in @_ready
    return

  handleError: (args...) =>
    console.log "Error:", args
    return

  handleMessage: (msg) =>
    console.log 'IN:', msg
    {id, service, args, error, cookies} = JSON.parse msg
    args = [args] unless Array.isArray args
    throw new ServerError error if error?
    @addCookies cookies if cookies?
    if id? and @callbacks[id]
      @callbacks[id] args...
    else if service? and @subscribe[service]
      fn args... for fn in @subscribe[service].listeners
    return

  handleClose: (args...) =>
    @connected = false
    cb args... for cb in @_close
    return

  # Utilities
  addCookies: (cookies) =>
    existing = @cookie()
    @cookie key, val for key, val of cookies when existing[key] isnt val
    return

  getSubscriber: (service) -> 
    sub = (cb) =>
      @subscribe[service].listeners.push cb
      return
    sub.listeners = []
    return sub

  getSender: (service) ->
    (args..., cb) =>
      id = @getId()
      @callbacks[id] = cb
      msg = JSON.stringify id: id, service: service, args: args, cookies: @cookie()
      console.log 'OUT:', msg
      @socket.send msg
      return

  getId: ->
    rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
    rand()+rand()+rand()

define "Vein", (-> Vein) if typeof define is 'function'
window.Vein = Vein
