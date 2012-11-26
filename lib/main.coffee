ProtoSock = require 'protosock'
server = require './Server'
client = require './Client'

module.exports =
  createServer: ProtoSock.createServerWrapper server
  createClient: ProtoSock.createClientWrapper client