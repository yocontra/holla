var server = holla.connect();

$(function(){
  $("#whoCall").hide();
  $("#whoAmI").change(function(){
    var name = $("#whoAmI").val();
    $("#whoAmI").remove();

    holla.createFullStream(function(err, stream) {
      holla.pipe(stream, $("#me"));

      // accept inbound
      server.identify(name, function(worked) {
        server.on("call", function(call) {
          console.log("Inbound call", call);

          call.addStream(stream);
          call.answer();

          call.ready(function(stream) {
            holla.pipe(stream, $("#them"));
          });
        });

        //place outbound
        $("#whoCall").show().change(function(){
          var toCall = $("#whoCall").val();
          var call = server.call(toCall);
          call.addStream(stream);
          call.ready(function(stream) {
            holla.pipe(stream, $("#them"));
          });
        });

      });
    });

  });
});