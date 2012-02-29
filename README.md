## Information

<table>
<tr>
<td>Package</td><td>vein</td>
</tr>
<tr>
<td>Description</td>
<td>RPC over WebSockets</td>
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
vein.add 'test', (reply, socket, hello) -> reply "Hello #{socket.remoteAddress}! You said '#{hello}'"
vein.add 'othertest', (reply, socket, hello) -> reply "Hello #{socket.remoteAddress} -  You said '#{hello}'"
```

### Client
```javascript
var vein = new Vein();
vein.ready(function(services) {
  console.log("Vein opened");

  vein.test('hello world', function(res) {
    console.log("Response: " + res);
  });
  vein.othertest('hi service', function(res) {
    console.log("Response 2: " + res);
  });
});

vein.close(function(){
  console.log("Vein closed");
});
```

## Examples

You can view further examples in the [example folder.](https://github.com/wearefractal/vein/tree/master/examples)

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
