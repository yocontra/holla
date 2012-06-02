http = require 'http'
should = require 'should'
Server = require '../'
{join} = require 'path'
{Client} = Server

randomPort = -> Math.floor(Math.random() * 1000) + 8000
port = randomPort()
serv = new Server http.createServer().listen port
getClient = -> new Client port: port, transports: ['websocket']

describe 'Vein', ->
  beforeEach ->
    delete serv.services[key] for key, val of serv.services when key isnt 'list'
    serv.stack = []
    serv.drop()

  describe 'services', ->
    it 'should add', (done) ->
      serv.add 'test', (res) -> res.send 'test'
      done()

    it 'should addFolder', (done) ->
      serv.addFolder join __dirname, "services"
      should.exist serv.services.test
      done()

    it 'should remove', (done) ->
      serv.add 'test', (res) -> res.send 'test'
      serv.remove 'test'
      done()

    it 'should call', (done) ->
      serv.add 'test', (res, numOne, numTwo) -> 
        numOne.should.equal 5
        numTwo.should.equal 6
        res.send numOne * numTwo

      client = getClient()
      client.ready (services) ->
        services.should.eql ['list', 'test']
        client.test 5, 6, (num) ->
          num.should.equal 30
          client.disconnect()
          done()

    it 'should transmit cookies', (done) ->
      serv.add 'test', (res, msg) -> 
        res.cookie 'result', 'oi'
        res.send()

      client = getClient()
      client.ready (services) ->
        client.test ->
          client.cookie('result').should.equal 'oi'
          client.disconnect()
          done()

  describe 'middleware', ->
    it 'should add', (done) ->
      serv.use (req, res, next) -> next()
      done()

    it 'should call', (done) ->
      called = false
      serv.use (req, res, next) -> next()
      serv.use (req, res, next) ->
        called = true
        next()
      serv.add 'test', (res) -> res.send()
      client = getClient()
      client.ready (services) ->
        client.test ->
          called.should.equal true
          client.disconnect()
          done()
