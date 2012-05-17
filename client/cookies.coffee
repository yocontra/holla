window.AIOCookie = (key, val, expires) ->
  all = ->
    out = {}
    for cookie in document.cookie.split ";"
      pair = cookie.split "="
      out[pair[0]] = pair[1]
    return out
  set = (key, val, expires) ->
    sExpires = ""
    sExpires = "; max-age=#{expires}" if typeof expires is 'number'
    sExpires = "; expires=#{expires}" if typeof expires is 'string'
    sExpires = "; expires=#{expires.toGMTString()}" if expires.toGMTString if typeof expires is 'object'
    document.cookie = "#{escape(key)}=#{escape(val)}#{sExpires}"
    return
  remove = (key) ->
    document.cookie = "#{escape(key)}=; expires=Thu, 01-Jan-1970 00:00:01 GMT; path=/"
    return

  return all() unless key
  return remove key if key and val is null
  return all()[key] if key and not val
  return set key, val, expires if key and val