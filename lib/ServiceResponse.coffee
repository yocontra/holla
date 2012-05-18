class ServiceResponse
  constructor: (@socket, msg) ->
    try
      @req = JSON.parse msg
    catch err
      return @error err
    return unless @req?.id? and @req?.service?
    @req.cookies ?= {}
    @valid = true

  valid: false

  getMessage: (args, err) =>
    JSON.stringify 
      id: @req.id
      service: @req.service
      args: args if args?
      cookies: @cookie() if @cookie()?
      error: if err?
        message: err.message
        type: err.type
        stack: err.stack

  getAnonymousMessage: (args) =>
    JSON.stringify
      service: @req.service
      args: args if args?

  publish: (args...) =>
    socket.send @getAnonymousMessage args for id, socket of @socket.server.clients
    return @

  send: (args...) =>
    @socket.send @getMessage args
    return @

  cookie: (key, val) =>
    return @req.cookies unless key or val
    if key and not val
      return @req.cookies[key]
    else
      @req.cookies[key] = val
      return @

  error: (err) =>
    err = new Error err unless err instanceof Error
    @socket.send @getMessage null, err
    return @

  close: => 
    @socket.close()
    return @

module.exports = ServiceResponse