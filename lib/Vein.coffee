{EventEmitter} = require 'events'
sockjs = require 'sockjs'

class Vein extends EventEmitter
  constructor: (server, opts) ->
    @server = sockjs.createServer opts
    @server.on 'connection', (socket) =>
      socket.write JSON.stringify id: 'services', args: Object.keys @routes
      socket.on 'data', (msg) => @route socket, msg
    @server.installHandlers server, prefix: '/vein'

  add: (route, fn) ->
    if typeof route is 'object'
      @routes[rt] = f for rt, f of route
    else
      @routes[route] = fn

  remove: (route) -> delete @routes[route]

  removeAll: -> routes = {}

  routes: {}

  route: (socket, msg) ->
    return unless typeof msg is 'string' and socket?
    try
      {id, service, args} = JSON.parse msg
    catch err
      return
    return unless service? and args? and id? and @routes[service]?
    reply = (args...) -> socket.write JSON.stringify id: id, args: args

    @routes[service] reply, socket, args...

module.exports = Vein