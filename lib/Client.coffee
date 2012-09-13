isBrowser = typeof window isnt 'undefined'

getId = =>
  rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
  return rand()+rand()+rand()

client = (opt) ->
  out =
    options:
      namespace: 'Vein'
      resource: 'default'

    start: ->
      @services = {}
      @callbacks = {}

    ready: (fn) ->
      return fn @services if @synced
      @once 'ready', fn

    validate: (socket, msg, done) ->
      return done false unless typeof msg is 'object'
      return done false unless typeof msg.type is 'string'
      if msg.type is 'response'
        return done false unless typeof msg.id is 'string'
        return done false unless typeof @callbacks[msg.id] is 'function'
        return done false unless typeof msg.service is 'string'
        return done false unless Array.isArray msg.args
      else if msg.type is 'services'
        return done false unless Array.isArray msg.args
      else
        return done false
      return done true

    error: (socket, err) -> throw err

    message: (socket, msg) ->
      if msg.type is 'response'
        @callbacks[msg.id] msg.args... if @callbacks[msg.id]?
        delete @callbacks[msg.id]
      else if msg.type is 'services'
        @services = msg.args
        @[k] = @getSender(socket,k) for k in @services
        @synced = true
        @emit 'ready', @services

    getSender: (socket, service) ->
      (args..., cb) =>
        id = getId()
        @callbacks[id] = cb
        socket.write
          type: 'request'
          id: id
          service: service
          args: args

  out.options[k]=v for k,v of opt
  return out

if isBrowser
  window.Vein = createClient: (opt={}) -> ProtoSock.createClient client opt
  define(->Vein) if typeof define is 'function'
else
  module.exports = client
