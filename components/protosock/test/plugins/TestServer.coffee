getId = =>
  rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
  rand()+rand()+rand()

module.exports = (serv) ->
  options:
    server: serv
    namespace: 'HelloWorld'
    resource: getId()