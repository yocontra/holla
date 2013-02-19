![status](https://secure.travis-ci.org/wearefractal/protosock.png?branch=master)

## Information

<table>
<tr> 
<td>Package</td><td>protosock</td>
</tr>
<tr>
<td>Description</td>
<td>Framework for creating websocket-based protocols</td>
</tr>
<tr>
<td>Node Version</td>
<td>>= 0.6</td>
</tr>
</table>

ProtoSock uses ES5 features so be sure to include es5shim on your page.

## Server Usage

```coffee-script
ps = require 'protosock'
plugin =
  # Server default options
  options:
    namespace: 'TestProtocol'
    resource: 'default'

  # Called on server construct
  start: ->

  # Message formatters
  inbound: (socket, msg, done) -> done JSON.parse msg
  outbound: (socket, msg, done) -> done JSON.stringify msg

  # Validation
  validate: (socket, msg, done) -> done true
  invalid: (socket, msg) ->

  # Socket handlers
  connect: (socket) ->
  message: (socket, msg) ->
  error: (socket, err) ->
  close: (socket, reason) ->

options =
  resources: 'coolpath'

server = ps.createServer httpServer, plugin, options
```

## Client Usage

```coffee-script
plugin =
  # Client default options
  options:
    namespace: 'TestProtocol'
    resource: 'default'

  # Called on client construct
  start: ->

  # Message formatters
  inbound: (socket, msg, done) -> done JSON.parse msg
  outbound: (socket, msg, done) -> done JSON.stringify msg

  # Validation
  validate: (socket, msg, done) -> done true
  invalid: (socket, msg) ->

  # Socket handlers
  connect: (socket) ->
  message: (socket, msg) ->
  error: (socket, err) ->
  close: (socket, reason) ->

options =
  resources: 'coolpath'

client = ProtoSock.createClient plugin, options
```

## LICENSE

(MIT License)

Copyright (c) 2012 Fractal <contact@wearefractal.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
