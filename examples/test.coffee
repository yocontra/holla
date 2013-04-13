rtc = holla.createClient debug: true
wireCall = (call) ->
  for name, user of call.users()
    do (user) ->
      user.ready ->
        console.log "#{user.name} ready"
        user.stream.pipe $(".them")

      user.on "answered", -> console.log "#{user.name} answered"
      user.on "declined", -> console.log "#{user.name} declined"

  call.on "end", -> $(".them").attr "src", ""

  $("#hangup").click -> call.end()

$ ->
  $("#me").hide()
  $("#them").hide()
  $("#whoCall").hide()
  $("#hangup").hide()
  $("#whoAmI").change ->
    name = $("#whoAmI").val()

    rtc.register name, (err) ->
      throw err if err
      console.log "Registered as #{name}!"
      $(".me").show()
      $(".them").show()
      $("#whoAmI").remove()
      $("#whoCall").show()
      $("#hangup").show()
    
      holla.createFullStream (err, stream) ->
        throw err if err
        stream.pipe $(".me")

        # accept inbound
        rtc.on "call", (call) ->
          console.log "Inbound call", call
          call.on 'error', (err) -> throw err
          call.setLocalStream stream
          call.answer()
          wireCall call
        
        # place outbound
        $("#whoCall").change ->
          toCall = $("#whoCall").val()
          rtc.createCall (err, call) ->
            throw err if err
            console.log "Created call", call
            call.on 'error', (err) -> throw err
            call.setLocalStream stream
            user = call.add toCall
            wireCall call
