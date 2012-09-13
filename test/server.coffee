http = require 'http'
should = require 'should'
Vein = require '../'
{join} = require 'path'

randomPort = -> Math.floor(Math.random() * 2000) + 8000

getServer = ->
  Vein.createServer
    server: http.createServer().listen randomPort()

getClient = (server) ->
  Vein.createClient
    host: server.server.httpServer.address().address
    port: server.server.httpServer.address().port
    resource: server.options.resource

describe 'Vein', ->
  describe 'services', ->
    it 'should add', (done) ->
      serv = getServer()
      serv.add 'test', (res) -> res.reply 'test'
      should.exist serv.services
      should.exist serv.services.test
      done()

    it 'should addFolder', (done) ->
      serv = getServer()
      serv.addFolder join __dirname, "services"
      should.exist serv.services
      should.exist serv.services.test
      done()

    it 'should remove', (done) ->
      serv = getServer()
      serv.add 'test', (res) -> res.reply 'test'
      should.exist serv.services
      should.exist serv.services.test
      serv.remove 'test'
      should.not.exist serv.services.test
      done()

    it 'should call', (done) ->
      serv = getServer()
      serv.add 'test', (res, numOne, numTwo) ->
        numOne.should.equal 5
        numTwo.should.equal 6
        res.reply numOne * numTwo

      client = getClient serv
      client.ready (services) ->
        client.connected.should.be.true
        services.should.eql ['test']
        client.test 5, 6, (num) ->
          num.should.equal 30
          done()

    it 'should call as fn', (done) ->
      serv = getServer()
      serv.add 'test', (res, numOne, numTwo) ->
        numOne.should.equal 5
        numTwo.should.equal 6
        res numOne * numTwo

      client = getClient serv
      client.ready (services) ->
        client.connected.should.be.true
        services.should.eql ['test']
        client.test 5, 6, (num) ->
          num.should.equal 30
          done()

  describe 'middleware', ->
    it 'should add', (done) ->
      serv = getServer()
      serv.use (req, res, next) -> next()
      done()

    it 'should call', (done) ->
      serv = getServer()
      called = false
      serv.use (req, res, next) -> next()
      serv.use (req, res, next) ->
        called = true
        next()
      serv.add 'test', (res) -> res.reply()

      client = getClient serv
      client.ready (services) ->
        client.test ->
          called.should.equal true
          done()

describe 'client', ->

  # Protosock is catching errors and handling them via an 'error' method in vein.
  # The interfaces need to match up for successful error handling.
  it 'should rethrow errors', (done) ->
    serv = getServer()
    client = getClient serv

    # intercept uncaught errors
    originalListener = process.listeners("uncaughtException").pop()
    process.once "uncaughtException", (error) ->

      should.exist error, 'expected snakes on a plane'
      error.toString().should.eql 'Error: snakes on a plane'

      # restore mocha's listener for uncaught errors
      process.listeners("uncaughtException").push originalListener

      done()

    # throw an error inside client.ready
    client.ready (services) ->
      throw new Error 'snakes on a plane'

  it 'should work on multiple clients', (done) ->
    serv = getServer()
    client = getClient serv
    client.ready (services) ->
      client2 = getClient serv
      client2.ready (services) -> done()

  it 'should disconnect after ready', (done) ->
    serv = getServer()
    client = getClient serv
    client.ready ->
      client.disconnect()
      done()
