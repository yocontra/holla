## Support

holla has full support for Chrome 24+ and Firefox 21+ (Currently Nightly)

## Example

### Server

```javascript
var holla = require('holla');
var server = http.createServer().listen(8080);
var rtc = holla.createServer(server);

console.log('Server running on port 8080');
```

Note: Express 3 is no longer a httpServer so you need to do something like:  
```javascript
var server = require('http').createServer(app).listen(8080);
```
before passing it to holla.createServer

### Client

Sending a call:

```javascript
var rtc = holla.createClient();

rtc.register("tom", function(err) {

  holla.createFullStream(function(err, stream) {
    rtc.createCall(function(err, call){
      call.setLocalStream(stream);
      call.add("bob");
    });
  });

});
```

Receiving a call:

```javascript
var rtc = holla.createClient();

rtc.register("bob", function(worked) {
  rtc.on("call", function(call) {

    holla.createFullStream(function(err, stream) {
      call.setLocalStream(stream);
      call.answer();
    });

  });
});
```

## Browser

### holla

#### .supported

true or false if WebRTC is supported in the browser

#### .createClient(options)

Takes some options to specify host (see source) - defaults to window.location.href. Returns a Client instance

#### .createStream(opt, cb)

Creates a WebRTC stream - opt looks like ```{video:true,audio:true}``` depending on the stream you want. cb signature is ```(err, stream)```

#### createFullStream(cb)

Sugar for ```.createStream({video:true,audio:true}, cb)```

#### createVideoStream(cb)

Sugar for ```.createStream({video:true,audio:false}, cb)```

#### createAudioStream(cb)

Sugar for ```.createStream({video:false,audio:true}, cb)```


### Client

#### .register(name, cb)

Registers your connection with the server under a name. cb receives an error if there was a problem.

#### .createCall(cb)

Creates a call with the server. Callback receives an error and the call instance.

#### Events

Client will emit reconnect, disconnect, call, and error events


### Call

#### .caller

User class for the caller. Will not exist if you started the call.

#### .user(name)

Gets a user in the call by name

#### .users()

Returns all users in the call

#### .setLocalStream(stream)

Adds your WebRTC stream to the call. Must be done before answering or sending a call.

#### .answer()

Accepts the call (inbound only)

#### .decline()

Declines the call (inbound only)

#### .end(release)

Ends the call (hangup and close connection). If release is true it will call releaseLocalStream() on the call.

#### releaseLocalStream()

Release use of the attached stream. Will make a users webcam light go off so they don't think you're spying.

#### mute()

Mutes the local user's audio to the remote user

#### unmute()

Unmutes the local user's audio to the remote user

#### Events

Call will emit userAdded, userRemoved, userAnswered, userDeclined, end, and error events

### User

TODO

## Examples

You can view more examples in the [example folder.](https://github.com/wearefractal/holla/tree/master/examples)

## Demo

There is a crappy demo up at [holla.jit.su](http://holla.jit.su)

## Adapters (complex use cases)

The holla server comes with a default adapter that uses an in-memory store and no auth to manage users. If you would like to override these preference just pass your overrides as the second object to ```.createServer(httpServer, {adapter: adapterObject})```.

An example adapter that uses redis instead of in-memory might look something like this (pseudo-code)

```coffee-script
# assume redis is a node-redis connection

adapter =
  register: (req, cb) ->
    client.hset "users", req.name, req.socket.id, cb

  getId: (name, cb) -> 
    client.hget "users", name (err, id) ->
      cb id

  unregister: (req, cb) ->
    client.hdel "users", req.name, cb

  getPresenceTargets: (req, cb) ->
    # these are the people notified on presence changes
    # this assumes contacts.{name} is a list of names you created somewhere else
    client.get "contacts.#{req.name}", (err, contacts) ->
      cb contacts
```

### Changing the name on register

You can set req.name before calling cb to change the name (useful if you send up a cookie in .register then do a lookup for the real name)

## Effects

There is effects.css in the repository with some common CSS classes you will want when dealing with RTC video tags (flip, shadow, reflect, fadein, etc.). These are prefixed with rtc (example: .rtc-flip)

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
