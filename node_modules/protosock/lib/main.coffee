util = require './util'
Client = require './Client'
defaultClient = require './defaultClient'

ps =
  createClientWrapper: (plugin) -> (opt) -> ps.createClient plugin, opt
  createClient: (plugin, opt) ->
    newPlugin = util.mergePlugins defaultClient, plugin
    return new Client newPlugin, opt

if !window?
  Server = require './Server'
  defaultServer = require './defaultServer'
  require("http").globalAgent.maxSockets = 999 # fix for multiple clients
  ps.createServer = (httpServer, plugin, opt) ->
    newPlugin = util.mergePlugins defaultServer, plugin
    return new Server httpServer, newPlugin, opt

  ps.createServerWrapper = (plugin) -> (httpServer, opt) -> ps.createServer httpServer, plugin, opt

module.exports = ps