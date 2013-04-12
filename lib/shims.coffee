# begin compatibility insanity

PeerConnection = window.mozRTCPeerConnection or window.PeerConnection or window.webkitPeerConnection00 or window.webkitRTCPeerConnection
IceCandidate = window.mozRTCIceCandidate or window.RTCIceCandidate
SessionDescription = window.mozRTCSessionDescription or window.RTCSessionDescription
MediaStream = window.MediaStream or window.webkitMediaStream
getUserMedia = navigator.mozGetUserMedia or navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.msGetUserMedia
URL = window.URL or window.webkitURL or window.msURL or window.oURL

if getUserMedia?
  getUserMedia = getUserMedia.bind navigator

browser = (if navigator.mozGetUserMedia then 'firefox' else 'chrome')
supported = (PeerConnection? and getUserMedia?)

extract = (str, reg) ->
  match = str.match reg
  return (if match? then match[1] else null)

replaceCodec = (line, codec) ->
  els = line.split ' '
  out = []
  for el, idx in els
    if idx is 3
      out[idx++] = codec
    if el isnt codec
      out[idx++] = el

  return out.join ' '

removeCN = (lines, mLineIdx) ->
  mLineEls = lines[mLineIdx].split ' '
  for line, idx in lines when line?
    payload = extract line, /a=rtpmap:(\d+) CN\/\d+/i
    if payload?
      cnPos = mLineEls.indexOf payload
      if cnPos isnt -1
        mLineEls.splice cnPos, 1
      lines.splice idx, 1

  lines[mLineIdx] = mLineEls.join ' '
  return lines

useOPUS = (sdp) ->
  lines = sdp.split '\r\n'
  [mLineIdx] = (idx for line,idx in lines when line.indexOf('m=audio') isnt -1)
  return sdp unless mLineIdx?
  for line, idx in lines when line.indexOf('opus/48000') isnt -1
    payload = extract line, /:(\d+) opus\/48000/i
    if payload?
      lines[mLineIdx] = replaceCodec lines[mLineIdx], payload
    break

  lines = removeCN lines, mLineIdx

  return lines.join '\r\n'

processSDPOut = (sdp) ->
  out = []
  if browser is 'firefox'
    addCrypto = "a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:BAADBAADBAADBAADBAADBAADBAADBAADBAADBAAD"
    for line in sdp.split '\r\n'
      out.push line
      out.push addCrypto if line.indexOf('m=') is 0
  else
    for line in sdp.split '\r\n'
      if line.indexOf("a=ice-options:google-ice") is -1
        out.push line
  return useOPUS out.join '\r\n'

processSDPIn = (sdp) -> return sdp

attachStream = (uri, el) ->
  if typeof el is "string"
    return attachStream uri, document.getElementById el
  else if el.jquery
    el.attr 'src', uri
    e.play() for e in el
  else
    el.src = uri
    el.play()
  return el

shim = ->
  return unless supported # no need to shim
  if browser is 'firefox'
    PeerConnConfig =
      iceServers: [
        url: "stun:23.21.150.121"
      ]

    mediaConstraints =
      mandatory:
        OfferToReceiveAudio: true
        OfferToReceiveVideo: true
        MozDontOfferDataChannel: true

    MediaStream::getVideoTracks = -> []
    MediaStream::getAudioTracks = -> []
  else
    PeerConnConfig = 
      iceServers: [
        url: "stun:stun.l.google.com:19302"
      ]
    mediaConstraints =
      mandatory:
        OfferToReceiveAudio: true
        OfferToReceiveVideo: true
      optional: [
        DtlsSrtpKeyAgreement: true
      ]

    unless MediaStream::getVideoTracks
      MediaStream::getVideoTracks = -> @videoTracks
      MediaStream::getAudioTracks = -> @audioTracks

    unless PeerConnection::getLocalStreams
      PeerConnection::getLocalStreams = -> @localStreams
      PeerConnection::getRemoteStreams = -> @remoteStreams
  
  MediaStream::pipe = (el) ->
    uri = URL.createObjectURL @
    attachStream uri, el
    return @

  out = 
    PeerConnection: PeerConnection
    IceCandidate: IceCandidate
    SessionDescription: SessionDescription
    MediaStream: MediaStream
    getUserMedia: getUserMedia
    URL: URL
    attachStream: attachStream
    processSDPIn: processSDPIn
    processSDPOut: processSDPOut
    PeerConnConfig: PeerConnConfig
    browser: browser
    supported: supported
    constraints: mediaConstraints
  return out

module.exports = shim()