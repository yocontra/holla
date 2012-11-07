ProtoSock = require '../'
should = require 'should'
require 'mocha'

httpServer = require('http').createServer()
httpServer.setMaxListeners -1

engineClient = require 'engine.io-client'
getClient = (srv) ->
  return new engineClient.Socket
    host: 'localhost'
    port: srv.server.httpServer.address().port
    path: "/#{srv.options.namespace}"
    resource: srv.options.resource

TestProtocol = require './plugins/TestServer'

describe 'Server', ->
  beforeEach -> httpServer.listen 9091
  afterEach -> httpServer.close()

  describe 'createServer()', ->
    it 'should construct from test protocol', (done) ->
      testProtocol = TestProtocol httpServer
      server = ProtoSock.createServer testProtocol
      should.exist server
      done()

  describe 'plugin interaction', ->
    describe 'start()', ->
      it 'should call when server is created', (done) ->
        testProtocol = TestProtocol httpServer
        testProtocol.start = ->
          @isBrowser.should.be.false
          @isServer.should.be.true
          done()
        server = ProtoSock.createServer testProtocol

    describe 'connect()', ->
      it 'should call when socket is connected', (done) ->
        testProtocol = TestProtocol httpServer
        testProtocol.connect = (socket) ->
          should.exist socket
          @disconnect()
          done()
        server = ProtoSock.createServer testProtocol
        client = getClient server

    describe 'inbound()', ->
      it 'should call when socket sends a message', (done) ->
        testProtocol = TestProtocol httpServer
        testProtocol.inbound = (socket, msg, next) ->
          should.exist socket
          should.exist msg
          should.exist next
          msg.should.equal JSON.stringify test: 'test'
          @disconnect()
          done()
        server = ProtoSock.createServer testProtocol
        client = getClient server
        client.on 'open', ->
          client.send JSON.stringify test: 'test'

    describe 'outbound()', ->
      it 'should call when server sends a message', (done) ->
        testProtocol = TestProtocol httpServer
        testProtocol.connect = (socket) ->
          should.exist socket
          socket.write test: 'test'

        testProtocol.outbound = (socket, msg, next) ->
          should.exist socket
          should.exist msg
          should.exist next
          should.exist msg.test
          msg.test.should.equal 'test'
          @disconnect()
          done()
        server = ProtoSock.createServer testProtocol
        client = getClient server

    describe 'validate()', ->
      it 'should call when socket sends a message', (done) ->
        testProtocol = TestProtocol httpServer
        testProtocol.validate = (socket, msg, validate) ->
          should.exist socket
          should.exist msg
          should.exist validate
          should.exist msg.test
          msg.test.should.equal 'test'
          @disconnect()
          done()
        server = ProtoSock.createServer testProtocol
        client = getClient server
        client.on 'open', ->
          client.send JSON.stringify test: 'test'

    describe 'invalid()', ->
      it 'should call when socket sends a message and validate returns false', (done) ->
        testProtocol = TestProtocol httpServer
        testProtocol.validate = (socket, msg, validate) -> validate false
        testProtocol.invalid = (socket, msg) ->
          should.exist socket
          should.exist msg
          should.exist msg.test
          msg.test.should.equal 'test'
          @disconnect()
          done()
        server = ProtoSock.createServer testProtocol
        client = getClient server
        client.on 'open', ->
          client.send JSON.stringify test: 'test'

    describe 'message()', ->
      it 'should call when socket sends a message and validate returns true', (done) ->
        testProtocol = TestProtocol httpServer
        testProtocol.validate = (socket, msg, validate) -> validate true
        testProtocol.message = (socket, msg) ->
          should.exist socket
          should.exist msg
          should.exist msg.test
          msg.test.should.equal 'test'
          @disconnect()
          done()
        server = ProtoSock.createServer testProtocol
        client = getClient server
        client.on 'open', ->
          client.send JSON.stringify test: 'test'

    describe 'error()', ->
      it 'should call when socket emits an error', (done) ->
        testProtocol = TestProtocol httpServer
        testProtocol.connect = (socket) -> socket.emit 'error', 'test'
        testProtocol.error = (socket, err) ->
          should.exist socket
          should.exist err
          should.exist err.message
          err.message.should.equal 'test'
          @disconnect()
          done()

        server = ProtoSock.createServer testProtocol
        client = getClient server

    describe 'close()', ->
      it 'should call when socket closes', (done) ->
        testProtocol = TestProtocol httpServer
        testProtocol.connect = (socket) -> socket.close()
        testProtocol.close = (socket, reason) ->
          should.exist socket
          should.exist reason
          @disconnect()
          done()

        server = ProtoSock.createServer testProtocol
        client = getClient server