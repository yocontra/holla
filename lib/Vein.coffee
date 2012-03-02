{EventEmitter} = require 'events'
sockjs = require 'sockjs'

class Vein extends EventEmitter

  constructor: (server, opts) ->
    @server = sockjs.createServer opts
    @server.on 'connection', (socket) =>
      @clients.push socket
      socket.write JSON.stringify id: 'services', args: Object.keys @routes
      socket.on 'data', (msg) => @route socket, msg
      socket.on 'close', =>
        idx = @clients.indexOf socket
        @clients.splice idx, idx

    @server.installHandlers server, prefix: '/vein'

  clients: [] # TODO: optional redis here

  # Routing
  routes: {}
  add: (route, fn) -> @routes[route] = fn
  remove: (route) -> delete @routes[route]

  route: (socket, msg) ->
    return unless typeof msg is 'string' and socket?
    try
      {id, service, args} = JSON.parse msg
    catch err
      return
    return unless service? and args? and id? and @routes[service]?

    write = (sock, args...) -> sock.write JSON.stringify id: id, service: service, args: args
    send = (args...) -> write socket, args...
    send.all = (args...) => write sock, args... for sock in @clients

    @routes[service] send, socket, args...

module.exports = Vein