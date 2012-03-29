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
    @callbacks['services'] = @handleServices
    @callbacks['session'] = @setSession
    @socket.onmessage = @handleMessage
    @socket.onclose = @handleClose
    return

  callbacks: {}
  subscribe: {}

  getSession: => cookies.getItem @options.sessionName
  setSession: (sess) =>
    cookies.setItem @options.sessionName, sess, @options.sessionLength
    return true

  clearSession: =>
    cookies.removeItem @options.sessionName
    return

  ready: (cb) -> @callbacks['ready'] = cb
  close: (cb) -> @callbacks['close'] = cb

  # Event handlers
  handleClose: => @callbacks['close']?()

  handleMessage: (e) =>
    {id, service, args} = JSON.parse e.data
    if @subscribe[service] and @subscribe[service].listeners
      fn args... for fn in @subscribe[service].listeners
    return unless @callbacks[id]
    keep = @callbacks[id] args...
    delete @callbacks[id] unless keep is true
    return

  handleServices: (services...) =>
    @[service] = @getSender service for service in services
    @subscribe[service] = @getListener service for service in services
    @callbacks['ready']? services
    delete @callbacks['ready']
    return

  # Utilities
  getListener: (service) => (cb) =>
    @subscribe[service].listeners ?= []
    @subscribe[service].listeners.push cb
    return

  getSender: (service) =>
    (args..., cb) =>
      id = @getId()
      @callbacks[id] = cb
      @socket.send JSON.stringify id: id, service: service, args: args, session: @getSession()
      return

  getId: ->
    rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
    rand()+rand()+rand()

if typeof define is 'function'
  define -> Vein
else
  window.Vein = Vein