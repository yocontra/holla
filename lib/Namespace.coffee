{readdirSync} = require 'fs'
{join, basename, extname} = require 'path'
async = require 'async'

class Namespace
  constructor: (@_name) ->
    @_services = {}
    @_stack = []

  add: (name, fn) -> @_services[name] = fn; @
  remove: (name) -> delete @_services[name]; @
  addFolder: (folder) ->
    for file in readdirSync folder
      ext = extname file
      serviceName = basename file, ext
      if require.extensions[ext]?
        service = require join folder, file
        @add serviceName, service
    return @

  use: (fn) -> @_stack.push(fn); @
  _middle: (msg, res, cb) ->
    return cb() unless @_stack.length isnt 0
    run = (middle, done) => middle msg, res, done
    async.forEachSeries @_stack, run, cb
    return

module.exports = Namespace