# begin compatibility insanity

# First we deal with vendor prefixes
PeerConnection = window.mozRTCPeerConnection or window.PeerConnection or window.webkitPeerConnection00 or window.webkitRTCPeerConnection
IceCandidate = window.mozRTCIceCandidate or window.RTCIceCandidate
SessionDescription = window.mozRTCSessionDescription or window.RTCSessionDescription
MediaStream = window.MediaStream or window.webkitMediaStream
getUserMedia = navigator.mozGetUserMedia or navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.msGetUserMedia
URL = window.URL or window.webkitURL or window.msURL or window.oURL

# getUserMedia errors unless it is bound to the scope of navigator
if getUserMedia?
  getUserMedia = getUserMedia.bind navigator

# Very simple browser detection for chrome and FF
browser = (if navigator.mozGetUserMedia then 'firefox' else 'chrome')
supported = (PeerConnection? and getUserMedia?)

# Simple util for dealing with regex matches
extract = (str, reg) ->
  match = str.match reg
  return (if match? then match[1] else null)

# replaceCodec takes an SDP line with a codec in it and replaces it with a new codec
replaceCodec = (line, codec) ->
  els = line.split ' '
  out = []
  for el, idx in els
    if idx is 3
      out[idx++] = codec
    if el isnt codec
      out[idx++] = el

  return out.join ' '

# Removes troublesome CN lines from SDP messages that causes certain browsers to crash
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

# Replace audio codecs in SDP with OPUS
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

# Use this to format all outbound SDP Messages

processSDPOut = (sdp) ->
  out = []
  if browser is 'firefox'
    # FF does not support crypto yet - chrome does not support unencrypted though.
    # If FF makes an offer to chrome you need to put a fake crypto key in or chrome will ignore it
    addCrypto = "a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:BAADBAADBAADBAADBAADBAADBAADBAADBAADBAAD"
    for line in sdp.split '\r\n'
      out.push line
      out.push addCrypto if line.indexOf('m=') is 0
  else
    for line in sdp.split '\r\n'
      if line.indexOf("a=ice-options:google-ice") is -1
        out.push line
  return useOPUS out.join '\r\n'

# Use this to format all inbound SDP messages - currently does nothing

processSDPIn = (sdp) -> return sdp

# Util for attaching a video stream to a DOM element

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

# Patches over RTC prototypes with missing functions
# Also exposes a config based on browser. FF and chrome require certain configs for interop
shim = ->
  return unless supported # no need to shim
  if browser is 'firefox'
    PeerConnConfig =
      iceServers: [
        url: "stun:23.21.150.121" # FF doesn't support resolving DNS in iceServers yet
      ]
    
    mediaConstraints =
      mandatory:
        OfferToReceiveAudio: true
        OfferToReceiveVideo: true
        MozDontOfferDataChannel: true # Tell FF not to put datachannel info in SDP or chrome will crash

    # FF doesn't expose this yet
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
    
    # API compat for older versions of chrome
    unless MediaStream::getVideoTracks
      MediaStream::getVideoTracks = -> @videoTracks
      MediaStream::getAudioTracks = -> @audioTracks

    unless PeerConnection::getLocalStreams
      PeerConnection::getLocalStreams = -> @localStreams
      PeerConnection::getRemoteStreams = -> @remoteStreams
  
  # Not a shim - custom to holla. Allows you to do stream.pipe(element) which is more elegant than attachStream(streamUri, el)
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
