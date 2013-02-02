Server = require './Server'

module.exports =
  createServer: (srv, opt={}) -> new Server srv, opt