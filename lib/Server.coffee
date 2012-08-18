{readdirSync} = require 'fs'
{join, basename, extname} = require 'path'
async = require 'async'

module.exports = (opt) ->
  out =
    options:
      namespace: 'Vein'
      resource: 'default'

    start: ->
      @services = {}
      @stack = []

    add: (name, fn) -> @services[name] = fn; @
    remove: (name) -> delete @services[name]; @
    addFolder: (folder) ->
      for file in readdirSync folder
        ext = extname file
        serviceName = basename file, ext
        if require.extensions[ext]?
          service = require join folder, file
          @add serviceName, service
      return @

    use: (fn) -> @stack.push(fn); @
    runStack: (msg, res, cb) ->
      return cb() unless @stack.length isnt 0
      run = (middle, done) => middle msg, res, done
      async.forEachSeries @stack, run, cb
      return

    validate: (socket, msg, done) ->
      return done false unless typeof msg is 'object'
      return done false unless typeof msg.type is 'string'
      if msg.type is 'request'
        return done false unless typeof msg.id is 'string'
        return done false unless typeof msg.service is 'string'
        return done false unless typeof @services[msg.service] is 'function'
        return done false unless Array.isArray msg.args
        return done false if msg.cookies? and typeof msg.cookies isnt 'object'
      else
        return done false
      return done true

    invalid: (socket, msg) -> socket.close()
    connect: (socket) ->
      socket.write
        type: 'services'
        args: Object.keys @services

    message: (socket, msg) ->
      try
        res = @getResponder socket, msg
        @runStack msg, res, =>
          @services[msg.service] res, msg.args...
      catch err
        @error socket, err

    getResponder: (socket, msg) ->
      cookie: (key, val) =>
        # TODO: implement expires
        return msg.cookies unless key or val
        if key and not val
          return msg.cookies[key]
        else
          msg.cookies[key] = val
          socket.write
            type: 'cookie'
            key: key
            val: val
          return @

      reply: (args...) =>
        # TODO: enforce a reply-once policy
        socket.write
          type: 'response'
          id: msg.id
          service: msg.service
          args: args
        return @

      disconnect: -> socket.close()

  out.options[k]=v for k,v of opt
  return out