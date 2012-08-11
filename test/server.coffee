http = require 'http'
should = require 'should'
Vein = require '../'
{join} = require 'path'

randomPort = -> Math.floor(Math.random() * 1000) + 8000

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
      client.on 'ready', (services) ->
        client.connected.should.be.true
        services.should.eql ['test']
        client.test 5, 6, (num) ->
          num.should.equal 30
          serv.destroy()
          done()

    it 'should transmit cookies', (done) ->
      serv = getServer()
      serv.add 'test', (res) ->
        res.cookie 'result', 'oi'
        res.reply 'goyta'

      client = getClient serv
      client.on 'ready', (services) ->
        client.test ->
          client.cookie('result').should.equal 'oi'
          serv.destroy()
          done()

  describe 'middleware', ->
    it 'should add', (done) ->
      serv = getServer()
      serv.use (req, res, next) -> next()
      serv.destroy()
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
      client.on 'ready', (services) ->
        client.test ->
          called.should.equal true
          serv.destroy()
          done()

  describe 'multiple clients', ->
    serv = getServer()
    it 'should work', (done) ->
      client = getClient serv
      client.on 'ready', (services) ->
        client.ready (services) ->
          done()

    it 'should work on the second client', (done) ->
      client = getClient serv
      client.on 'ready', (services) ->
        done()