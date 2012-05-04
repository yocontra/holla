cookies =
  getItem: (key) ->
    return unless cookies.hasItem key
    return unescape document.cookie.replace(new RegExp("(?:^|.*;\\s*)" + escape(key).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*"), "$1")

  setItem: (key, val, expires) ->
    sExpires = ""
    sExpires = "; max-age=#{expires}" if typeof expires is 'number'
    sExpires = "; expires=#{expires}" if typeof expires is 'string'
    sExpires = "; expires=#{expires.toGMTString()}" if expires.toGMTString if typeof expires is 'object'
    document.cookie = "#{escape(key)}=#{escape(val)}#{sExpires}"
    return

  removeItem: (key) ->
    document.cookie = "#{escape(key)}=; expires=Thu, 01-Jan-1970 00:00:01 GMT; path=/"
    return

  hasItem: (key) ->
    ep = new RegExp "(?:^|;\\s*)" + (escape(key).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")
    return ep.test document.cookie

class Vein
  constructor: (@options={}) ->
    # Valid options:
    # host - server running vein (default: location.origin)
    # prefix - vein endpoint (default: "vein")
    # sessionName - cookie name (default: "VEINSESSID-[prefix]")
    # sessionLength - time before cookie expires (default: session)

    @options.prefix ?= 'vein'
    @options.host ?= location.origin
    @options.sessionName ?= "VEINSESSID-#{@options.prefix}"

    @socket = new SockJS "#{@options.host}/#{@options.prefix}", null, @options
    @callbacks['methods'] = @handleMethods
    @callbacks['session'] = @setSession
    @socket.onmessage = @handleMessage
    @socket.onclose = @handleClose
    return

  connected: null
  callbacks:
    ready:[]
    close:[]

  subscribe: {}

  getSession: => cookies.getItem @options.sessionName
  setSession: (sess) =>
    cookies.setItem @options.sessionName, sess, @options.sessionLength
    return true

  clearSession: =>
    cookies.removeItem @options.sessionName
    return

  ready: (cb) ->
    @callbacks['ready'].push cb
    cb @methods if @connected is true
  close: (cb) -> 
    @callbacks['close'].push cb
    cb @methods if @connected is false

  # Event handlers
  handleReady: (@methods) =>
    @connected = true
    cb methods for cb in @callbacks['ready']
  handleClose: =>
    @connected = false
    cb() for cb in @callbacks['close']

  handleMessage: (e) =>
    {id, method, params, err} = JSON.parse e.data
    params = [params] unless Array.isArray params
    if @subscribe[method] and @subscribe[method].listeners
      fn params... for fn in @subscribe[method].listeners
    return unless @callbacks[id]
    console.log "[Vein] Incoming message: #{id}-#{method} #{JSON.stringify(params)}"
    keep = @callbacks[id] params...
    delete @callbacks[id] unless keep is true
    return

  handleMethods: (methods...) =>
    @[method] = @getSender method for method in methods
    @subscribe[method] = @getListener method for method in methods
    @handleReady methods
    return

  # Utilities
  getListener: (method) => (cb) =>
    @subscribe[method].listeners ?= []
    @subscribe[method].listeners.push cb
    return

  getSender: (method) =>
    (params..., cb) =>
      id = @getId()
      @callbacks[id] = cb
      console.log "[Vein] Outgoing message: #{@getSession()}-#{id}-#{method} #{JSON.stringify(params)}"
      @socket.send JSON.stringify id: id, method: method, params: params, session: @getSession()
      return

  getId: ->
    rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
    rand()+rand()+rand()

if typeof define is 'function'
  define -> Vein
else
  window.Vein = Vein
