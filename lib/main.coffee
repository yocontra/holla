client = require './Client'

`//if node`
ProtoSock = require 'protosock'
server = require './Server'
vein =
  createClient: (opt={}) -> ProtoSock.createClient client opt
  createServer: (opt={}) -> ProtoSock.createServer server opt
module.exports = vein
return
`//end`

window.Vein = createClient: (opt={}) -> ProtoSock.createClient client opt
define(->Vein) if typeof define is 'function'