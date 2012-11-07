util = require './util'

ps =
  createClient: (plugin) ->
    Client = require './Client'
    defaultClient = require './defaultClient'
    newPlugin = util.mergePlugins defaultClient, plugin
    err = util.validatePlugin newPlugin
    throw new Error "Plugin validation failed: #{err}" if err?
    return new Client newPlugin

`// if node`
require("http").globalAgent.maxSockets = 999 # fix for multiple clients
ps.createServer = (plugin) ->
  Server = require './Server'
  defaultServer = require './defaultServer'
  newPlugin = util.mergePlugins defaultServer, plugin
  err = util.validatePlugin newPlugin
  throw new Error "Plugin validation failed: #{err}" if err?
  return new Server newPlugin
module.exports = ps
return
`// end`

window.ProtoSock = ps
#define(->ProtoSock) if typeof define is 'function'