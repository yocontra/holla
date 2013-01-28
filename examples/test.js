var server = holla.connect();
var server2 = holla.connect();

holla.createFullStream(function(err, stream) {
  if(err) return console.log(err);

  server.identify("tom", function(worked) {
    var call = server.call("bob");
    call.on("answered", function() {
      console.log("Remote user answered the call");
    });

    call.addStream(stream);
    holla.pipe(stream, $("#me"));
  });

  server2.identify("bob", function(worked) {
    server2.on("call", function(call) {
      console.log("Inbound call", call);

      call.addStream(stream);
      call.answer();
      holla.pipe(stream, $("#me"));

      call.ready(function(stream) {
        holla.pipe(stream, $("#them"));
      });


    });
  });
  
});