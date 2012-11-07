module.exports = util =
  extendSocket: (Socket) ->
    nu = require './Socket'
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

  validatePlugin: (plugin) ->
    # options
    return 'missing options object' unless typeof plugin.options is 'object'
    return 'namespace option required' unless typeof plugin.options.namespace is 'string'
    return 'resource option required' unless typeof plugin.options.resource is 'string'

    # plugin structure
    return 'missing inbound formatter' unless typeof plugin.inbound is 'function'
    return 'missing outbound formatter' unless typeof plugin.outbound is 'function'
    return 'missing validate' unless typeof plugin.validate is 'function'
    return

  isBrowser: ->
    `// if node`
    return false
    `// end`
    return true