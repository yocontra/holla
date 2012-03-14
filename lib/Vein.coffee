{EventEmitter} = require 'events'
sockjs = require 'sockjs'

class Vein extends EventEmitter

  constructor: (server, @opts={}) ->
    @opts.prefix ?= '/vein'

    @server = sockjs.createServer @opts
    @server.on 'connection', (socket) =>
      socket.write JSON.stringify id: 'services', args: Object.keys @routes # send down list of services
      socket.on 'data', (msg) => @route socket, msg
      unless @opts.noTrack
        @clients[socket.id] = socket
        socket.on 'close', => delete @clients[socket.id]

    @server.installHandlers server, @opts

  clients: {} # TODO: optional redis here

  # Routing
  routes: {}

  add: (route, fn) -> @routes[route] = fn
  remove: (route) -> delete @routes[route]

  route: (socket, msg) ->
    return unless typeof msg is 'string' and socket?
    try
      {id, service, args, session} = JSON.parse msg
    catch err
      return
    return unless service? and args? and id? and @routes[service]?

    write = (sock, args...) -> sock.write JSON.stringify id: id, service: service, args: args
    send = (args...) -> write socket, args...
    unless @opts.noTrack
      send.all = (args...) => write sock, args... for id, sock of @clients
    send.session = (sess) => 
      socket.session = sess
      socket.write JSON.stringify id: 'session', args: [sess]
    socket.session = session if session?
    @routes[service] send, socket, args...

module.exports = Vein