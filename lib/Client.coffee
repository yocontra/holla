isBrowser = typeof window isnt 'undefined'

getId = =>
  rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
  return rand()+rand()+rand()

client = (opt) ->
  out =
    options:
      namespace: 'Vein'
      resource: 'default'

    start: ->
      @services = {}
      @callbacks = {}
      @connected = false

    ready: (fn) ->
      return fn @services if @connected is true
      @on 'ready', fn

    inbound: (socket, msg, done) ->
      try
        done JSON.parse msg
      catch err
        @error socket, err

    outbound: (socket, msg, done) ->
      try
        done JSON.stringify msg
      catch err
        @error socket,  err

    validate: (socket, msg, done) ->
      return done false unless typeof msg is 'object'
      return done false unless typeof msg.type is 'string'
      if msg.type is 'response'
        return done false unless typeof msg.id is 'string'
        return done false unless typeof @callbacks[msg.id] is 'function'
        return done false unless typeof msg.service is 'string'
        return done false unless Array.isArray msg.args
      else if msg.type is 'cookie'
        return done false unless typeof msg.key is 'string'
      else if msg.type is 'services'
        return done false unless Array.isArray msg.args
      else
        return done false
      return done true

    error: (socket, err) -> throw err
    close: (socket, reason) ->
      @connected = false
      @emit 'close', reason

    message: (socket, msg) ->
      if msg.type is 'response'
        @callbacks[msg.id] msg.args...
      else if msg.type is 'cookie'
        @cookie msg.key, msg.val
      else if msg.type is 'services'
        @services = msg.args
        @[k]=@getSender(socket,k) for k in @services
        @connected = true
        @emit 'ready', @services

    getSender: (socket, service) ->
      (args..., cb) =>
        id = getId()
        @callbacks[id] = cb
        socket.write
          type: 'request'
          id: id
          service: service
          args: args
          cookies: @cookie()

    cookie: (key, val, expires) ->
      if isBrowser
        all = ->
          out = {}
          for cookie in document.cookie.split ";"
            pair = cookie.split "="
            continue unless pair[0] and pair[1]
            out[pair[0].trim()] = pair[1].trim()
          return out
        set = (key, val, expires) ->
          sExpires = ""
          sExpires = "; max-age=#{expires}" if typeof expires is 'number'
          sExpires = "; expires=#{expires}" if typeof expires is 'string'
          sExpires = "; expires=#{expires.toGMTString()}" if expires.toGMTString if typeof expires is 'object'
          document.cookie = "#{escape(key)}=#{escape(val)}#{sExpires}"
          return
        remove = (key) ->
          document.cookie = "#{escape(key)}=; expires=Thu, 01-Jan-1970 00:00:01 GMT; path=/"
          return
      else
        @cookies ?= {}
        all = => @cookies
        set = (key, val, expires) =>
          @cookies[key] = val
          return
        remove = (key) =>
          delete @cookies[key]
          return
      return all() unless key
      return remove key if key and val is null
      return all()[key] if key and not val
      return set key, val, expires if key and val

  out.options[k]=v for k,v of opt
  return out

if isBrowser
  window.Vein = createClient: (opt={}) -> ProtoSock.createClient client opt
else
  module.exports = client