![status](https://secure.travis-ci.org/wearefractal/holla.png?branch=master)

## Information

<table>
<tr>
<td>Package</td>
<td>holla</td>
</tr>
<tr>
<td>Description</td>
<td>WebRTC Sugar</td>
</tr>
<tr>
<td>Node Version</td>
<td>>= 0.6</td>
</tr>
</table>

## Example

### Server

```javascript
var holla = require('holla');
var server = http.createServer().listen(8080);

var rtc = holla.createServer(server);

var users = {};
rtc.identify = function (req, cb) {
  users[req.name] = req.socket.id;
  cb();
};

rtc.getId = function (name, cb) {
  cb(users[name]);
};

rtc.close = function (req, cb) {
  delete users[req.name];
  cb();
};


console.log 'Server running on port 8080'
```
Note: Express 3 is no longer a httpServer so you need to do something like:  
```javascript
var server = require('http').createServer(app).listen(8080);
```
before passing it to holla.createServer

### Client

Sending a call:

```javascript
var server = holla.connect();
server.identify("tom", function(worked) {
  var call = server.call("bob");
  call.on("answered", function() {
    console.log("Remote user answered the call");
  });

  holla.createFullStream(function(err, stream) {
    if(err) return console.log(err);
    call.addStream(stream);
    holla.pipe(stream, $("#me"));
  });
});
```

Receiving a call:

```javascript
var server = holla.connect();
server.identify("bob", function(worked) {
  server.on("call", function(call) {
    console.log("Inbound call", call);
    call.answer();
    holla.createFullStream(function(err, stream) {
      if(err) return console.log(err);
      call.addStream(stream);
      holla.pipe(stream, $("#me"));

      call.ready(function(stream) {
        holla.pipe(stream, $("#them"));
      });
    });
  });
});
```

## Examples

You can view more examples in the [example folder.](https://github.com/wearefractal/holla/tree/master/examples)

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
