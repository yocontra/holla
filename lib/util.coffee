module.exports =
  parseCookie: (str) ->
    obj = {}
    pairs = str.split /[;,] */

    for pair in pairs
      eqlIndex = pair.indexOf "="
      key = pair.substr(0, eqlIndex).trim()
      val = pair.substr(++eqlIndex, pair.length).trim()
      val = val.slice(1, -1) if "\"" is val[0]
      unless obj[key]?
        val = val.replace /\+/g, " "
        try
          obj[key] = decodeURIComponent val
        catch err
          if err instanceof URIError
            obj[key] = val
    return obj