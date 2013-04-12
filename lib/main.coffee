Server = require './Server'

module.exports =
  Server: Server
  createServer: (httpServer, opt={}) -> new Server httpServer, opt