isBrowser = typeof window isnt 'undefined'

getId = =>
  rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
  return rand()+rand()+rand()

class ClientNamespace
  constructor: (@_socket, @_name, @_services) ->
    @_callbacks = {}
    @[service] = @_getSender service for service in @_services

  _getSender: (service) ->
      (args..., cb) =>
        id = getId()
        if typeof cb is 'function'
          @_callbacks[id] = cb
        else
          args.push cb
        @_socket.write
          type: 'request'
          id: id
          ns: @_name
          service: service
          args: args

client =
  options:
    namespace: 'Vein'
    resource: 'default'

  start: ->
    @namespaces = {}

  ready: (fn) ->
    return fn @ns('main')._services, @namespaces if @synced
    @once 'ready', fn

  ns: (name) -> @namespaces[name]
  validate: (socket, msg, done) ->
    return done false unless typeof msg is 'object'
    return done false unless typeof msg.type is 'string'
    if msg.type is 'response'
      return done false unless typeof msg.id is 'string'
      return done false unless typeof msg.ns is 'string'
      return done false unless @ns(msg.ns)?
      return done false unless typeof msg.service is 'string'
      return done false unless typeof @ns(msg.ns)._callbacks[msg.id] is 'function'
      return done false unless Array.isArray msg.args
    else if msg.type is 'services'
      return done false unless typeof msg.args is 'object'
    else
      return done false
    return done true

  error: (socket, err) -> @emit 'error', err, socket

  message: (socket, msg) ->
    if msg.type is 'response'
      @ns(msg.ns)._callbacks[msg.id] msg.args...
      delete @ns(msg.ns)._callbacks[msg.id]
    else if msg.type is 'services'
      @namespaces[k] = new ClientNamespace(socket, k, v) for k,v of msg.args
      # clone main services
      @[k]=@ns('main')[k] for k in msg.args.main

      @synced = true
      @emit 'ready', @ns('main')._services, @namespaces

if isBrowser
  window.Vein = createClient: ProtoSock.createClientWrapper client
else
  module.exports = client
