util = require '../lib/util'
should = require 'should'
require 'mocha'

vm = require 'vm'

describe 'util', ->
  describe 'isBrowser()', ->
    it 'should return false under node', (done) ->
      res = util.isBrowser()
      should.exist res
      res.should.be.false
      done()
    ###
    it 'should return true under browser', (done) ->
      # emulate a browser
      sandbox = vm.createContext 
        window: {}
        util: util
        module: null
        global: null
        process: null

      vm.runInNewContext 'res = util.isBrowser();', sandbox, 'test.vm'
      should.exist sandbox.res
      sandbox.res.should.be.true
      done()
    ###