rtc = holla.createClient debug: true
wireCall = (call) ->
  call.ready ->
    for stream in call.streams()
      holla.pipe stream, $(".them") # TODO: stream.attachTo

  call.on "hangup", -> $(".them").attr "src", ""
  $("#hangup").click -> call.end()

$ ->
  $("#me").hide()
  $("#them").hide()
  $("#whoCall").hide()
  $("#hangup").hide()
  $("#whoAmI").change ->
    name = $("#whoAmI").val()
    $(".me").show()
    $(".them").show()
    $("#whoAmI").remove()
    $("#whoCall").show()
    $("#hangup").show()

    holla.createFullStream (err, stream) ->
      throw err if err
      holla.pipe stream, $(".me")
      
      rtc.register name, (err) ->
        throw err if err
        console.log "Registered as #{name}!"

        # accept inbound
        rtc.on "call", (call) ->
          console.log "Inbound call", call
          call.setLocalStream stream
          call.answer()
          wireCall call
        
        # place outbound
        $("#whoCall").change ->
          toCall = $("#whoCall").val()
          rtc.createCall (err, call) ->
            throw err if err
            console.log "Created call", call
            call.setLocalStream stream
            call.add toCall, (err) ->
              throw err if err?
              wireCall call
