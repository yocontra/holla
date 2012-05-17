## Information

<table>
<tr>
<td>Package</td><td>vein</td>
</tr>
<tr>
<td>Description</td>
<td>RPC/PubSub via WebSockets</td>
</tr>
<tr>
<td>Node Version</td>
<td>>= 0.4</td>
</tr>
</table>

## Example

### Server

##### With server

```javascript
var Vein = require('vein');
var server = http.createServer().listen(8080);
var vein = new Vein(server);

vein.add('greetings', function (res, first, last){
  res.send("Hey there " + first + " " + last!");
});
```

##### Without server

```javascript
var Vein = require('vein');
var vein = new Vein(8080);

vein.add('greetings', function (res, first, last){
  res.send("Hey there " + first + " " + last!");
});
```

### Client

```javascript
var vein = new Vein();
vein.ready(function (){
  vein.greetings("John", "Foobar", function (res){
    // res === "Hey there John Foobar!"
  });
});
```

## Usage

### Server
```javascript
var Vein = require('vein');

var vein = new Vein(8080, {
/*
  Valid options:
  path - prefix path (default: "/vein")
  resource - change to allow multiple servers for one endpoint (default: "default")
*/
});

// A service is a function that gets called every time a client calls it
// The format is function (send, socket, args...)
// args can be any JSON-friendly data sent from the client
// You can pass any JSON-friendly objects as arguments to the send
// and they will be applied to the callback on the client.
vein.add('someService', function (res, name, num) {
  res.send("Hey there " + name + " I got your number " + num);
});

// The server can assign and access cookies to the client via res.cookie().
vein.add('login', function (res, username, password) {
  if (res.cookie('login')) {
    res.send('You already logged in!');
  } else if (username === 'username' && password === 'pass123') {
    res.cookie('login', 'success!');
    res.send();
  } else {
    res.send('Invalid username or password');
  }
});

// You can use res.publish to send a message to everyone subscribing to a service
vein.add('someOtherService', function (res, msg) {
  res.publish(msg);
});
```

### Browser Client

```javascript
var vein = new Vein({
/*
  Valid options:
  host - server location (default: window.location.hostname)
  port - server port (default: window.location.port)
  secure - use SSL (default: window.location.protocol)
  path - prefix path (default: "/vein")
  resource - change to allow multiple servers for one endpoint (default: "default")
*/
});

//When the vein is ready this function will be called
vein.ready(function (services) {
  // services is an array of service names available to use
  // When calling a service the format is vein.<service name>(args..., callback)
  // You can pass any JSON-friendly objects as arguments.
  vein.someService('john', 2, function (err, result) {
    console.log(result);
  });

  // Prefixing a service with .subscribe allows the server to send unsolicited messages
  // to the client. Subscribing to a service does not communicate to the server in any way.
  vein.subscribe.someOtherService(function (message) {
    console.log(message);
  });

  //The server can assign cookies to the client
  // You can read and write these cookies by using vein.cookie()
  vein.login('username', 'pass123', function (err) {
    if (err) {
      alert(err);
      vein.cookie('login', 'fail'); //write
    } else {
      console.log(vein.cookie('login')); //read
      vein.cookie('login', null); //delete
    }
  });
});

//If the vein is closed this function will be called
vein.close(function () {
  console.log("Connection lost!");
});
```

## More Examples

You can view a web-based chat example in the [example folder.](https://github.com/wearefractal/vein/tree/master/examples)

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
