{EventEmitter} = require 'events'
async = require 'async'
engine = require 'engine.io'
ServiceResponse = require './ServiceResponse'

class Vein
  constructor: (hook, @options={}, cb) ->
    @options.path ?= '/vein'
    if typeof hook is 'number'
      @server = engine.listen hook
    else
      @server = engine.attach hook, @options
      @server.httpServer = hook
    @services.list = (res) => res.send Object.keys @services
    @server.on 'connection', @handleConnection

  close: -> @server.httpServer.close()

  drop: -> @server.close()

  stack: []
  services: {}

  use: (fn) -> @stack.push fn
  add: (name, fn) -> @services[name] = fn
  remove: (name) -> delete @services[name]

  # Core
  handleConnection: (socket) =>
    socket.on 'message', (msg) => @handleMessage socket, msg

  handleMessage: (socket, msg) =>
    res = new ServiceResponse socket, msg
    @runMiddleware res.req, res, (err) =>
      return res.error err if err?
      return res.error "Invalid message" unless res.valid is true
      return res.error "Invalid service" unless @services[res.req.service]?
      @services[res.req.service] res, res.req.args...
      #try
      #  @services[res.req.service] res, res.req.args...
      #catch err
      #  return res.error err

  runMiddleware: (req, res, cb) =>
    run = (middle, done) => middle req, res, done
    async.forEachSeries @stack, run, cb

Vein.Client = require '../client/Vein'
module.exports = Vein