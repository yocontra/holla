async = require 'async'
engine = require 'engine.io'
ServiceResponse = require './ServiceResponse'
{EventEmitter} = require 'events'
{readdirSync} = require 'fs'
{join, basename, extname} = require 'path'

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
    return

  close: -> 
    @server.httpServer.close()
    return @

  drop: -> 
    @server.close()
    return @

  stack: []
  services: {}

  use: (fn) -> 
    @stack.push fn
    return @

  add: (name, fn) -> 
    @services[name] = fn
    return @

  addFolder: (folder) ->
    for file in readdirSync folder
      serviceName = basename file, extname file
      try
        service = require join folder, file
        @add serviceName, service
    return @

  remove: (name) -> 
    delete @services[name]
    return @

  # Core
  handleConnection: (socket) =>
    socket.on 'message', (msg) => @handleMessage socket, msg

  handleMessage: (socket, msg) =>
    res = new ServiceResponse socket, msg
    @runMiddleware res.req, res, (err) =>
      return res.error err if err?
      return res.error "Invalid message" unless res.valid is true
      return res.error "Invalid service" unless @services[res.req.service]?
      try
        @services[res.req.service] res, res.req.args...
      catch err
        return res.error err

  runMiddleware: (req, res, cb) =>
    run = (middle, done) => middle req, res, done
    async.forEachSeries @stack, run, cb

Vein.Client = require '../client/Vein'
module.exports = Vein