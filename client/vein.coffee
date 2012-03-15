cookies =
  getItem: (sKey) ->
    return unless cookies.hasItem sKey
    unescape document.cookie.replace(new RegExp("(?:^|.*;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*"), "$1")

  setItem: (sKey, sValue, vEnd, sPath, sDomain, bSecure) ->
    if vEnd
      sExpires = "; max-age=#{vEnd}" if typeof vEnd is 'number'
      sExpires = "; expires=#{vEnd}" if typeof vEnd is 'string'
      sExpires = "; expires=#{vEnd.toGMTString()}" if vEnd.hasOwnProperty("toGMTString") if typeof vEnd is 'object'
    sDomain = (if sDomain then "; domain=" + sDomain else "")
    sPath = (if sPath then "; path=" + sPath else "")
    sExpires = (if sExpires then sExpires else "")
    bSecure = (if bSecure then "; secure" else "")
    console.log "Setting cookie to #{escape(sKey)}=#{escape(sValue)}#{sExpires}#{sDomain}#{sPath}#{bSecure}"
    document.cookie = "#{escape(sKey)}=#{escape(sValue)}#{sExpires}#{sDomain}#{sPath}#{bSecure}"

  removeItem: (sKey) ->
    return unless cookies.hasItem sKey
    console.log "Deleting cookie #{sKey}"
    document.cookie = "#{escape(sKey)}=; expires=Thu, 01-Jan-1970 00:00:01 GMT; path=/"

  hasItem: (sKey) ->
    (new RegExp("(?:^|;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test document.cookie

class Vein
  constructor: (@url=location.origin, @options={}) ->
    @options.prefix ?= 'vein'
    @options.sessionName ?= "VEINSESSID-#{@options.prefix}"
    @options.sessionExpires ?= new Date new Date().getTime() + 1 * 24 * 60 * 60 * 1000
    @socket = new SockJS "#{@url}/#{@options.prefix}", null, @options
    @callbacks['services'] = @handleServices
    @callbacks['session'] = @handleSession
    @socket.onmessage = @handleMessage
    @socket.onclose = @handleClose
    @session = @cookie()
    return

  callbacks: {}
  subscribe: {}
  session: undefined

  clearSession: =>
    @session = undefined
    @cookie '', true
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
    delete @callbacks[id] unless keep
    return

  handleServices: (services...) =>
    @[service] = @getSender service for service in services
    @subscribe[service] = @getListener service for service in services
    @callbacks['ready']? services
    delete @callbacks['ready']
    return

  handleSession: (sess) =>
    @session = sess
    @cookie sess
    return true # keep this callback open - session can be changed multiple times

  # Utilities
  getListener: (service) => (cb) =>
    @subscribe[service].listeners ?= []
    @subscribe[service].listeners.push cb
    return

  getSender: (service) =>
    (args..., cb) =>
      id = @getId()
      @callbacks[id] = cb
      @socket.send JSON.stringify id: id, service: service, args: args
      return

  cookie: (sess, del) ->
    name = @options.sessionName
    return cookies.removeItem name if del
    if sess
      return cookies.setItem name, sess, @options.sessionExpires
    else
      return cookies.getItem name

  getId: ->
    rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
    rand()+rand()+rand()

if typeof define is 'function'
  define -> Vein
else
  window.Vein = Vein