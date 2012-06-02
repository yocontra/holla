require 'should'
http = require 'http'
Server = require '../'
{Client} = Server

randomPort = -> Math.floor(Math.random() * 1000) + 8000
port = randomPort()
serv = new Server http.createServer().listen port
getClient = -> new Client port: port, transports: ['websocket']

describe 'multiple clients', ->
  beforeEach -> serv.drop()

  it 'should work', (done) ->
    return done()
    client = getClient()
    client.ready (services) ->
      client.disconnect()
      done()

  it 'should work on the second client', (done) ->
    return done()
    client = getClient()
    client.ready (services) ->
      client.disconnect()
      done()