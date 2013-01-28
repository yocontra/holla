var server = holla.connect();

$(function(){
  $("#whoCall").hide();
  $("#hangup").hide();
  $("#messages").hide();

  server.on("presence", function(user){
    if (user.online) {
      console.log(user.name + " is online.");
    } else {
      console.log(user.name + " is offline.");
    }
  });

  $("#whoAmI").change(function(){
    var name = $("#whoAmI").val();
    $("#whoAmI").remove();
    $("#whoCall").show();
    $("#hangup").show();
    $("#messages").show();

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
          call.on("hangup", function() {
            $("#them").attr('src', '');
          });
          $("#hangup").click(function(){
            call.end();
          });

          $("#whatSay").change(function(){
            var msg = $("#whatSay").val();
            if (msg === "") return;
            call.chat(msg);
            $("#chat").append("<b>"+server.user+"</b>: " + msg + "<br/>");
            $("#whatSay").val('');
          });
          call.on("chat", function(msg){
            $("#chat").append("<b>"+call.user+"</b>: " + msg + "<br/>");
          });
        });

        //place outbound
        $("#whoCall").change(function(){
          var toCall = $("#whoCall").val();
          var call = server.call(toCall);
          call.addStream(stream);
          call.ready(function(stream) {
            holla.pipe(stream, $("#them"));
          });
          call.on("hangup", function() {
            $("#them").attr('src', '');
          });
          $("#hangup").click(function(){
            call.end();
          });
          $("#whatSay").change(function(){
            var msg = $("#whatSay").val();
            if (msg === "") return;
            call.chat(msg);
            $("#chat").append("<b>"+server.user+"</b>: " + msg + "<br/>");
            $("#whatSay").val('');
          });
          call.on("chat", function(msg){
            $("#chat").append("<b>"+call.user+"</b>: " + msg + "<br/>");
          });
        });

      });
    });

  });
});