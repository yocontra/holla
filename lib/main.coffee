ProtoSock = require 'protosock'
server = require './Server'
client = require './Client'

module.exports =
  createServer: (opt={}) -> ProtoSock.createServer server opt
  createClient: (opt={}) -> ProtoSock.createClient client opt