var server = holla.connect();
var server2 = holla.connect();

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

server2.identify("bob", function(worked) {
  server2.on("call", function(call) {
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