var server = holla.createClient({debug:true});

$(function(){
  $("#me").hide();
  $("#them").hide();
  $("#whoCall").hide();
  $("#hangup").hide();

  server.on("presence", function(user){
    if (user.online) {
      console.log(user.name + " is online.");
    } else {
      console.log(user.name + " is offline.");
    }
  });

  $("#whoAmI").change(function(){
    var name = $("#whoAmI").val();
    $(".me").show();
    $(".them").show();
    $("#whoAmI").remove();
    $("#whoCall").show();
    $("#hangup").show();

    holla.createFullStream(function(err, stream) {
      if (err) throw err;
      holla.pipe(stream, $(".me"));

      // accept inbound
      server.register(name, function(worked) {
        server.on("call", function(call) {
          console.log("Inbound call", call);

          call.addStream(stream);
          call.answer();

          call.ready(function(stream) {
            holla.pipe(stream, $(".them"));
          });
          call.on("hangup", function() {
            $(".them").attr('src', '');
          });
          $("#hangup").click(function(){
            call.end();
          });
        });

        //place outbound
        $("#whoCall").change(function(){
          var toCall = $("#whoCall").val();
          var call = server.call(toCall);
          call.addStream(stream);
          call.ready(function(stream) {
            holla.pipe(stream, $(".them"));
          });
          call.on("hangup", function() {
            $(".them").attr('src', '');
          });
          $("#hangup").click(function(){
            call.end();
          });
        });

      });
    });

  });
});