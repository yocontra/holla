server = require './Server'
ProtoSock = require 'protosock'

module.exports =
  createServer: ProtoSock.createServerWrapper server