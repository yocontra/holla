sock =
  write: (msg) ->
    @parent.outbound @, msg, (fmt) => @send fmt
    return @

  disconnect: (r) -> 
    @close r
    return @


module.exports = sock