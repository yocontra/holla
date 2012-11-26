![status](https://secure.travis-ci.org/wearefractal/vein.png?branch=master)

## Information

<table>
<tr>
<td>Package</td>
<td>vein</td>
</tr>
<tr>
<td>Description</td>
<td>RPC via WebSockets</td>
</tr>
<tr>
<td>Node Version</td>
<td>>= 0.6</td>
</tr>
</table>

Vein uses ES5 features so be sure to include es5shim on your page.

## Example

### Server

```javascript
var Vein = require('vein');
var server = http.createServer().listen(8080);
var vein = Vein.createServer(server);

vein.add('multiply', function (res, numOne, numTwo){
  res.reply(numOne * numTwo);
});
```

### Client

```javascript
var vein = Vein.createClient();
vein.ready(function (services){
  vein.multiply(2, 5, function (num){
    // num === 10
  });
});
```

## Server Usage

### Create

```
-- Options --
resource - change to allow multiple servers on one port (default: "default")
```

```javascript
var Vein = require('vein');
var vein = Vein.createServer(httpServer, {options});
```

### Adding services

Arguments passed to res.reply() will be applied to the callback on the client

```javascript
vein.add('getNumber', function (res, name, num) {
  res.reply("Hey there " + name + " I got your number " + num);
});
```

### Middleware

You can use middleware to add layers in front of your services. Any arguments passed into next will be thrown as an error on the client and end the middleware chain.

```javascript
vein.use(function(req, res, next){
  if (req.service == 'login') {
    next();
  } else {
    if (res.cookie('login') == 'success!') {
      next();
    } else {
      res.disconnect();
    }
  }
});
```

### Testing

Vein supports calling the res object as a function. This makes it easier to integrate vanilla-JS services into vein. The only difference is that you still have to put the callback first (this is to prevent headaches with variable arguments from the client).

```javascript
vein.add('echoUser', function (res, username, password) {
  res(username, password);
});
```

## Client Usage

### Create

```
-- Options --
host - server location (default: window.location.hostname)
port - server port (default: window.location.port)
secure - use SSL (default: window.location.protocol)
resource - change to allow multiple servers on one port (default: "default")
```

```javascript
var vein = Vein.createClient({options});
```

### Ready

When the connection has been established your callback will be called with an array of services available.

```javascript
vein.on('ready', function (services) {
  //Start doing stuff!
});
```

### Calling services

When calling a service the format is vein.serviceName(args..., callback)

```javascript
vein.getNumber('john', 2, function (msg) {
  console.log(msg);
});
```
  
### Close

If the connection has been closed this will be called.

```javascript
vein.on('close', function (reason) {
  console.log("Connection lost due to", reason);
});
```

## Examples

You can view a tiny addition sample and more in the [example folder.](https://github.com/wearefractal/vein/tree/master/examples)

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
