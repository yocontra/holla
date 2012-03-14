class Vein
  constructor: (@url=location.origin, @options={}) ->
    @options.prefix ?= '/vein'
    #@options.sessionExpires ?= -1
    @options.sessionName ?= 'VSESSID'

    @socket = new SockJS "#{@url}#{@options.prefix}", null, @options
    @callbacks['services'] = @handleServices
    @callbacks['session'] = @handleSession
    @socket.onmessage = @handleMessage
    @socket.onclose = @handleClose
    @session = @cookie()
    return

  callbacks: {}
  subscribe: {}
  session: null

  clearSession: =>
    @session = null
    @cookie 'bye', true

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
    true # keep this callback open - session can be changed multiple times

  # Utilities
  getListener: (service) => (cb) =>
    @subscribe[service].listeners ?= []
    @subscribe[service].listeners.push cb
    return

  getSender: (service) =>
    (args..., cb) =>
      id = @getId()
      @callbacks[id] = cb
      @socket.send JSON.stringify id: id, service: service, args: args, session: @session
      return

  cookie: (sess, del=false) ->
    name = @options.sessionName
    expiry = (if del then -1 else @options.sessionExpires)
    if sess
      if expiry
        if typeof expiry is 'number'
          date = new Date
          date.setTime date.getTime() + (expiry * 24 * 60 * 60 * 1000)
        else if expiry.toUTCString
          date = expiry
      expires = (if date then ";expires=#{date.toUTCString()}" else "")
      document.cookie = "#{name}=#{encodeURIComponent(sess)}#{expires}"
    else
      if document.cookie and document.cookie.length isnt 0
        for cookie in document.cookie.split ";"
          if cookie.substring(0, (name.length + 1)) is "#{name}="
            return decodeURIComponent cookie.substring name.length + 1

  getId: ->
    rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
    rand()+rand()+rand()

if typeof define is 'function'
  define Vein
else
  window.Vein = Vein