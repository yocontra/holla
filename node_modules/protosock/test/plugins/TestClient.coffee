module.exports = (serv) ->
  options:
    host: 'localhost'
    port: serv.server.httpServer.address().port
    namespace: serv.options.namespace
    resource: serv.options.resource