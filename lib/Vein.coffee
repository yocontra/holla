{EventEmitter} = require 'events'
ServiceResponse = require './ServiceResponse'
engine = require './engine.io'

class Vein
  constructor: (hook, @options={}) ->
    @options.path ?= '/vein'
    if typeof hook is 'number'
      @server = engine.listen hook
    else
      @server = engine.attach hook, @options
    @services.list = (res) => res.send Object.keys @services
    @server.on 'connection', @handleConnection

  close: -> @server.close()

  services: {}

  add: (name, fn) -> @services[name] = fn
  remove: (name) -> delete @services[name]

  # Core
  handleConnection: (socket) =>
    socket.on 'message', (msg) => @handleMessage socket, msg

  handleMessage: (socket, msg) =>
    res = new ServiceResponse socket, msg
    # TODO: middleware here
    return res.error "Invalid message" unless res.valid is true
    return res.error "Invalid service" unless @services[res.req.service]?
    try
      @services[res.req.service] res, res.req.args...
    catch err
      return res.error err

module.exports = Vein
