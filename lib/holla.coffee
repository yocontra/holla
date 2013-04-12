Client = require './Client'
Call = require './Call'
shims = require './shims'

holla =
  createClient: (opt={}) -> new Client opt
  Call: Call
  Client: Client
  shims: shims
  supported: shims.supported
  config: shims.PeerConnConfig

  createStream: (opt, cb) ->
    return cb "Missing getUserMedia" unless shims.getUserMedia?
    err = cb
    succ = (s) -> cb null, s
    shims.getUserMedia opt, succ, err
    return holla

  createFullStream: (cb) -> holla.createStream {video:true,audio:true}, cb
  createVideoStream: (cb) -> holla.createStream {video:true,audio:false}, cb
  createAudioStream: (cb) -> holla.createStream {video:false,audio:true}, cb

module.exports = holla