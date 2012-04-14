## Information

<table>
<tr>
<td>Package</td><td>vein</td>
</tr>
<tr>
<td>Description</td>
<td>WebSocket RPC</td>
</tr>
<tr>
<td>Node Version</td>
<td>>= 0.4</td>
</tr>
</table>

## Example

### Server

```javascript
var Vein = require('vein');
var server = http.createServer().listen(8080);
var rpc = new Vein(server);

rpc.add('greetings', function (send, socket, first, last){
  send("Hey there " + first + " " + last!");
});
```

### Client

```javascript
var vein = new Vein();
vein.ready(function (){
  vein.greetings("John", "Foobar", function (res){
     // res === "Hey there John Foobar!"
    console.log(res);
  });
});
```

## Usage

Documentation is horrible. Will update later.

### Server
```javascript
var http = require('http');
var Vein = require('vein');
var server = http.createServer().listen(8080);

var vein = new Vein(server, {
  //options go here
});
/*
  Valid options:
  prefix - vein endpoint (default: "vein")
  sessionName - cookie name (default: "VEINSESSID-[prefix]")
  noTrack - disable pubsub for performance (default: false)
  response_limit - reopen socket after this much data (default: 128k)
*/

// A service is a function that gets called every time a client calls it
// The format is function (send, socket, args...)
// args can be any JSON-friendly data sent from the client
// You can pass any JSON-friendly objects as arguments to the send
// and they will be applied to the callback on the client.
vein.add('someService', function (send, socket, name, num) {
  send("Hey there " + name + " I got your number " + num);
});

// The server can assign a session to the client via send.session.
// Any services called will have access to the session value via socket.session
// This session will persist between page loads/connects based on your settings
// send.session is a simple way to set a tracking cookie not a session store
vein.add('login', function (send, socket, username, password) {
  if (username === 'username' && password === 'pass123') {
    send.session('success! (some unique key)');
    send(); // Call the login callback with no error
  } else {
    send('Invalid username or password');
  }
});

// If you have tracking enabled (noTrack=false) you can use send.all
// to broadcast a message to all currently connected clients that are subscribed to the service
// A hash of clients is available in vein.clients
vein.add('someOtherService', function (send, socket, msg) {
  send.all(msg);
});
```

### Browser Client

```javascript
var vein = new Vein({
  //options go here
});
/*
  Valid options:
  host - server running vein (default: location.origin)
  prefix - vein endpoint (default: "vein")
  sessionName - cookie name (default: "VEINSESSID-[prefix]")
  sessionLength - time before cookie expires (default: session)
  debug - extra information (default: false)
*/

//When the vein is ready this function will be called
vein.ready(function (services) {
  // services is an array of service names available to use
  // Any code using vein should be kicked off here
  // When calling a service the format is vein.<service name>(args..., callback)
  // You can pass any JSON-friendly objects as arguments and they will be applied to the
  // service on the server.
  vein.someService('john', 2, function (err, result) {
    console.log(result);
  });

  // Prefixing a service with .subscribe allows the server to send unsolicited messages
  // to the client. Subscribing to a service does not communicate to the server in any way.
  vein.subscribe.someOtherService(function (message) {
    console.log(message);
  });

  // When the server assigns a session it is saved as a cookie with the client preferences.
  // Make sure the client and server cookie preferences match.
  // Session data can be accessed via .getSession() and .clearSession()
  vein.login('username', 'pass123', function (err) {
    if (err) {
      alert(err);
    } else {
      console.log(vein.getSession());
      console.log(vein.clearSession());
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
