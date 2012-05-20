class ServerError extends Error
  name: "ServerError"
  constructor: ({@message, @type, @stack}) ->

module.exports = ServerError