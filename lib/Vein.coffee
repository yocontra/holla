{EventEmitter} = require 'events'
sockjs = require 'sockjs'

class Vein extends EventEmitter

  constructor: (server, @opts={}) ->
    @opts.prefix ?= 'vein'
    @opts.sessionName ?= "VEINSESSID-#{@opts.prefix}"
    @opts.prefix = "/#{@opts.prefix}"

    @server = sockjs.createServer @opts
    @server.on 'connection', (socket) =>
      socket.write JSON.stringify id: 'methods', params: Object.keys @routes # send down list of methods
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
      {id, method, params, session} = JSON.parse msg
    catch err
      return
    return unless method? and params? and id? and @routes[method]?
    write = (sock, params...) -> sock.write JSON.stringify id: id, method: method, params: params, error: null
    send = (params...) -> write socket, params...
    unless @opts.noTrack
      send.all = (params...) => write sock, params... for id, sock of @clients
    send.session = (sess) =>
      socket.session = sess
      socket.write JSON.stringify id: 'session', params: [sess]
    socket.session = session
    @routes[method] send, socket, params...

module.exports = Vein
