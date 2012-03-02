class Vein
  constructor: (url=location.origin, options) ->
    @socket = new SockJS "#{url}/vein", null, options
    @callbacks['services'] = @handleInitial
    @socket.onmessage = @handleMessage
    @socket.onclose = @handleClose
    return

  callbacks: {}
  subscribe: {}

  ready: (cb) -> @callbacks['ready'] = cb
  close: (cb) -> @callbacks['close'] = cb

  # Event handlers
  handleClose: => @callbacks['close']?()

  handleMessage: (e) =>
    {id, service, args} = JSON.parse e.data
    if @subscribe[service] and @subscribe[service].listeners
      fn args... for fn in @subscribe[service].listeners
    return unless @callbacks[id]
    @callbacks[id] args...
    delete @callbacks[id]
    return

  handleInitial: (services...) =>
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
      @socket.send JSON.stringify id: id, service: service, args: args
      return

  getId: ->
    rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
    rand()+rand()+rand()

window.Vein = Vein