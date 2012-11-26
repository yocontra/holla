http = require 'http'
https = require 'https'
should = require 'should'
Vein = require '../'
{join} = require 'path'
fs = require 'fs'

randomPort = -> Math.floor(Math.random() * 2000) + 8000

getServer = ->
  Vein.createServer http.createServer().listen randomPort()

getClient = (server) -> 
  Vein.createClient 
    host: server.httpServer.address().address
    port: server.httpServer.address().port
    resource: server.options.resource

getHTTPSServer = ->
  opt =
    key: fs.readFileSync join __dirname, './server.key'
    cert: fs.readFileSync join __dirname, './server.crt'
  Vein.createServer https.createServer(opt).listen randomPort()

getHTTPSClient = (server) ->
  Vein.createClient 
    host: server.httpServer.address().address
    port: server.httpServer.address().port
    resource: server.options.resource
    secure: true

describe 'Vein', ->
  describe 'services', ->
    it 'should add', (done) ->
      serv = getServer()
      serv.add 'test', (res) -> res.reply 'test'
      done()

    it 'should addFolder', (done) ->
      serv = getServer()
      serv.addFolder join __dirname, "services"
      done()

    it 'should remove', (done) ->
      serv = getServer()
      serv.add 'test', (res) -> res.reply 'test'
      serv.remove 'test'
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

    it 'should call without client callback', (done) ->
      serv = getServer()
      serv.add 'test', (res, numOne, numTwo) -> 
        numOne.should.equal 5
        numTwo.should.equal 6
        done()

      client = getClient serv
      client.ready (services) ->
        client.connected.should.be.true
        services.should.eql ['test']
        client.test 5, 6

    it 'should call with ns', (done) ->
      serv = getServer()
      serv.add 'test', -> throw 'NS confused'
      serv.ns('wat').add 'test', (res, numOne, numTwo) -> 
        numOne.should.equal 5
        numTwo.should.equal 6
        res.reply numOne * numTwo

      client = getClient serv
      client.ready (services) ->
        client.connected.should.be.true
        services.should.eql ['test']
        client.ns('wat').test 5, 6, (num) ->
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

    it 'should call with ns', (done) ->
      serv = getServer()
      called = false
      serv.ns('wat').use (req, res, next) -> next()
      serv.ns('wat').use (req, res, next) ->
        called = true
        next()
      serv.ns('wat').add 'test', (res) -> res.reply()

      client = getClient serv
      client.ready (services) ->
        client.ns('wat').test ->
          called.should.equal true
          done()

describe 'client', ->
  it 'should connect over https', (done) ->
    serv = getHTTPSServer()
    client = getHTTPSClient serv
    client.ready (services) ->
      should.exist services
      done()
      
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