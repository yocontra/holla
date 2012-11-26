Namespace = require './Namespace'

module.exports =
  options:
    namespace: 'Vein'
    resource: 'default'

  start: ->
    @namespaces = {}
    @ns 'main'

  ns: (name) -> @namespaces[name] ?= new Namespace name
  add: (args...) -> @ns('main').add args...
  remove: (args...) -> @ns('main').remove args...
  addFolder: (args...) -> @ns('main').addFolder args...
  use: (args...) -> @ns('main').use args...

  validate: (socket, msg, done) ->
    return done false unless typeof msg is 'object'
    return done false unless typeof msg.type is 'string'
    if msg.type is 'request'
      return done false unless typeof msg.id is 'string'
      return done false unless typeof msg.service is 'string'
      return done false unless typeof msg.ns is 'string'
      return done false unless @namespaces[msg.ns]?
      return done false unless typeof @namespaces[msg.ns]._services[msg.service] is 'function'
      return done false unless Array.isArray msg.args
    else
      return done false
    return done true

  invalid: (socket, msg) -> socket.close()
  connect: (socket) ->
    strut = {}
    strut[name] = Object.keys ns._services for name, ns of @namespaces
    socket.write
      type: 'services'
      args: strut

  message: (socket, msg) ->
    res = @getResponder socket, msg
    @ns(msg.ns)._middle msg, res, =>
      @ns(msg.ns)._services[msg.service] res, msg.args...

  getResponder: (socket, msg) ->
    responder = (args...) ->
      # TODO: enforce a reply-once policy
      socket.write
        type: 'response'
        id: msg.id
        ns: msg.ns
        service: msg.service
        args: args
      return @

    responder.reply = responder
    responder.socket = socket
    return responder

    disconnect: -> socket.close()