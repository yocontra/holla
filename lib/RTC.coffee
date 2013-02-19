PeerConnection = PeerConnection or webkitPeerConnection00 or webkitRTCPeerConnection or mozRTCPeerConnection
IceCandidate = RTCIceCandidate or mozRTCIceCandidate 
SessionDescription = mozRTCSessionDescription or RTCSessionDescription
MediaStream = webkitMediaStream or MediaStream
getUserMedia = (navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.mozGetUserMedia or navigator.msGetUserMedia).bind navigator
URL = URL or webkitURL or msURL or oURL

browser = (if mozGetUserMedia then 'firefox' else 'chrome')
supported = (PeerConnection? and getUserMedia?)

processSDP = (sdp) ->
  return sdp unless browser is 'mozilla'
  addCrypto = "a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  out = []
  for line in sdp.split '\r\n'
    out.push line
    out.push addCrypto if ('m=' in search) isnt -1
  return out.join '\r\n'

attachStream = (uri, el) ->
  srcAttr = (if browser is 'mozilla' then 'mozSrcObject' else 'src')
  if typeof el is "string"
    return attachStream uri, document.getElementById el
  else if el.jquery
    el.attr srcAttr, uri
    e.play() for e in el
  else
    el[srcAttr] = uri
    el.play()
  return stream

shim = ->
  return unless supported # no need to shim
  if browser is 'mozilla'
    PeerConnConfig =
      iceServers: [
        url: "stun:23.21.150.121"
      ]
      optional: []

    MediaStream::getVideoTracks = -> []
    MediaStream::getAudioTracks = -> []
  else
    PeerConnConfig = 
      iceServers: [
        url: "stun:stun.l.google.com:19302"
      ]
      optional: [
        DtlsSrtpKeyAgreement: true
      ]
    if MediaStream::getVideoTracks
      MediaStream::getVideoTracks = -> @videoTracks
      MediaStream::getAudioTracks = -> @audioTracks

    if PeerConnection::getLocalStreams
      PeerConnection::getLocalStreams = -> @localStreams
      PeerConnection::getRemoteStreams = -> @remoteStreams

shim()

module.exports =
  PeerConnection: PeerConnection
  IceCandidate: IceCandidate
  SessionDescription: SessionDescription
  MediaStream: MediaStream
  getUserMedia: getUserMedia
  URL: URL
  attachStream: attachStream
  PeerConnConfig: PeerConnConfig
  supported: supported