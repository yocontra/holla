nu = require './Socket'

util =
  extendSocket: (Socket) ->
    Socket.prototype extends nu

  mergePlugins: (args...) ->
    newPlugin = {}
    for plugin in args
      for k,v of plugin
        if typeof v is 'object' and k isnt 'server'
          newPlugin[k] = util.mergePlugins newPlugin[k], v
        else
          newPlugin[k] = v
    return newPlugin

module.exports = util