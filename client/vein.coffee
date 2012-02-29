getId = ->
  rand = -> (((1 + Math.random()) * 0x10000) | 0).toString 16
  ""+rand()+rand()+rand()+rand()+rand()+rand()

class Vein
  constructor: (url, options) ->
    url ?= "http://#{location.host}"
    @socket = new SockJS "#{url}/vein", null, options

    @callbacks['services'] = @setup # 'services' cb is used to define RPs
    @socket.onmessage = (e) =>
      {id, args} = JSON.parse e.data
      return unless id and @callbacks[id]
      @callbacks[id] args...
      delete @callbacks[id]

    @socket.onclose = => @callbacks['close']?()
    return

  ready: (cb) -> @callbacks['ready'] = cb
  close: (cb) -> @callbacks['close'] = cb

  setup: (services...) =>
    for service in services
      do (service) ->
        @[service] = (args..., cb) -> # wrap socket send
          id = getId()
          @callbacks[id] = cb
          @socket.send JSON.stringify id: id, service: service, args: args

    @callbacks['ready']? services
    # Clean up
    delete @callbacks['ready']
    delete @callbacks['services']
    return

  callbacks: {}

window.Vein = Vein
# AMD compatibility
window.define ["https://d1fxtkz8shb9d2.cloudfront.net/sockjs-0.2.js"], window.Vein if window.define?