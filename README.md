## Information

<table>
<tr>
<td>Package</td><td>vein</td>
</tr>
<tr>
<td>Description</td>
<td>WebSocket RPC and PubSub</td>
</tr>
<tr>
<td>Node Version</td>
<td>>= 0.4</td>
</tr>
</table>

## Usage

### Server
```coffee-script
http = require 'http'
Vein = require 'vein'

server = http.createServer().listen 8080

vein = new Vein server
vein.add 'test', (send, socket, hello) ->
  send "test - #{hello}"

# send data... will send a response to the socket that made the request
# send.all data... will send a message to every socket currently connected
vein.add 'pubtest', (send, socket, hello) ->
  send.all "pubtest - #{hello}"

vein.add 'subtest', (send, socket, hello) ->
  send "subtest - #{hello}"
  send "subtest - #{hello}"
```

### Client
```coffee-script
vein = new Vein

vein.ready (services) ->
  console.log "Vein opened"
  vein.test "success", (res) ->
    console.log res

  vein.pubtest "success", (res) ->
    console.log res

  # Listen for unsolicited messages with .subscribe
  # this callback will be called as many times as the server wants
  vein.subscribe.subtest (res) -> console.log res

vein.close -> console.log "Vein closed"
```

## Examples

You can view a web chat example in the [example folder.](https://github.com/wearefractal/vein/tree/master/examples)

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
