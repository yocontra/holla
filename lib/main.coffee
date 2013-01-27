Server = require './server'

module.exports =
  createServer: (srv, opt={}) -> new Server srv, opt