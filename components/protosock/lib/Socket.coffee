module.exports =
  write: (msg) ->
    @parent.outbound @, msg, (formatted) => @send formatted
    ###
    @parent.outbound @, msg, (formatted) =>
      if @connected is true
        @send formatted
      else
        (@buffer?=[]).push formatted
    ###
    return @

  disconnect: (args...) -> 
    @close args...
    return @