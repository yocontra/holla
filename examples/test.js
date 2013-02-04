var server = holla.createClient({debug:true});

var sendChat = function(){
  var msg = $("#whatSay").val();
  if (msg === "") return;
  this.chat(msg);
  $("#chat").append("<b>"+server.user+"</b>: " + msg + "<br/>");
  $("#whatSay").val('');
};

var handleChat = function(msg){
  $("#chat").append("<b>"+this.user+"</b>: " + msg + "<br/>");
};

$(function(){
  $("#me").hide();
  $("#them").hide();
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
    $("#me").show();
    $("#them").show();
    $("#whoAmI").remove();
    $("#whoCall").show();
    $("#hangup").show();
    $("#messages").show();

    holla.createFullStream(function(err, stream) {
      if (err) throw err;
      holla.pipe(stream, $("#me"));

      // accept inbound
      server.register(name, function(worked) {
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

          $("#whatSay").change(sendChat.bind(call));
          call.on("chat", handleChat.bind(call));
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
          $("#whatSay").change(sendChat.bind(call));
          call.on("chat", handleChat.bind(call));
        });

      });
    });

  });
});