ServerError = require './ServerError'
isBrowser = typeof window isnt 'undefined'
eio = require (if isBrowser then 'node_modules/engine.io-client/lib/engine.io-client' else 'engine.io-client')

class Vein extends eio.EventEmitter
  constructor: (@options={}) ->
    if isBrowser
      @options.host ?= window.location.hostname
      @options.port ?= (if window.location.port.length > 0 then parseInt window.location.port else 80)
      @options.secure ?= (window.location.protocol is 'https:')

    @options.path ?= '/vein'
    @options.forceBust ?= true
    @options.debug ?= false

    @socket = new eio.Socket @options
    @socket.on 'open', @handleOpen
    @socket.on 'error', @handleError
    @socket.on 'message', @handleMessage
    @socket.on 'close', @handleClose

    @connected = false
    @services = null
    @callbacks = {}
    return

  cookie: (key, val, expires) =>
    if typeof window isnt 'undefined' # browser
      all = ->
        out = {}
        for cookie in document.cookie.split ";"
          pair = cookie.split "="
          continue unless pair[0] and pair[1]
          out[pair[0].trim()] = pair[1].trim()
        return out
      set = (key, val, expires) ->
        sExpires = ""
        sExpires = "; max-age=#{expires}" if typeof expires is 'number'
        sExpires = "; expires=#{expires}" if typeof expires is 'string'
        sExpires = "; expires=#{expires.toGMTString()}" if expires.toGMTString if typeof expires is 'object'
        document.cookie = "#{escape(key)}=#{escape(val)}#{sExpires}"
        return
      remove = (key) ->
        document.cookie = "#{escape(key)}=; expires=Thu, 01-Jan-1970 00:00:01 GMT; path=/"
        return
    else # node
      @cookies ?= {}
      all = => @cookies
      set = (key, val, expires) =>
        @cookies[key] = val
        return
      remove = (key) =>
        delete @cookies[key]
        return
    return all() unless key
    return remove key if key and val is null
    return all()[key] if key and not val
    return set key, val, expires if key and val

  disconnect: => 
    @socket.close()
    return

  connect: =>
    @socket.open()
    return

  ready: (cb) ->
    @on 'ready', cb
    cb @services if @connected
    return

  close: (cb) -> 
    @on 'close', cb
    cb() unless @connected
    return

  refresh: (cb) => 
    @getSender('__list') (services) =>
      @services = services
      @[name] = @getSender name for name in services
      cb services
    return
  
  # Event handlers
  handleOpen: =>
    @emit 'open'
    @refresh (services) =>
      @connected = true
      @emit 'ready', services
    return

  handleError: (args...) =>
    @emit 'error', args...
    return

  handleMessage: (msg) =>
    @emit 'inbound', msg
    {id, service, args, error, cookies} = JSON.parse msg
    args = [args] unless Array.isArray args
    throw new ServerError error if error?
    @addCookies cookies if cookies?
    @callbacks[id]? args...
    return

  handleClose: (args...) =>
    @connected = false
    @emit 'close', args...
    return

  # Utilities
  addCookies: (cookies) ->
    existing = @cookie()
    @cookie key, val for key, val of cookies when existing[key] isnt val
    return

  getSender: (service) ->
    (args..., cb) =>
      id = @getId()
      @callbacks[id] = cb
      msg = JSON.stringify id: id, service: service, args: args, cookies: @cookie()
      @emit 'outbound', msg
      @socket.send msg
      return

  getId: =>
    rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
    rand()+rand()+rand()

if typeof define is 'function'
  define -> Vein

window.Vein = Vein if isBrowser
module.exports = Vein
