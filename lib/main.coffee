Server = require './Server'

module.exports =
  createServer: (httpServer, opt={}) -> new Server httpServer, opt