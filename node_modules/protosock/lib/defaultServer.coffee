def =
  options: {}
  start: ->

  inbound: (socket, msg, done) ->
    try
      done JSON.parse msg
    catch e
      @error socket, e
    
  outbound: (socket, msg, done) ->
    try
      done JSON.stringify msg
    catch e
      @error socket, e

  validate: (socket, msg, done) -> done true
  invalid: (socket, msg) ->

  connect: (socket) ->
  message: (socket, msg) ->
  error: (socket, err) ->
  close: (socket, reason) ->

module.exports = def