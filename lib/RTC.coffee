PeerConnection = window.mozRTCPeerConnection or window.PeerConnection or window.webkitPeerConnection00 or window.webkitRTCPeerConnection
IceCandidate = window.mozRTCIceCandidate or window.RTCIceCandidate
SessionDescription = window.mozRTCSessionDescription or window.RTCSessionDescription
MediaStream = window.MediaStream or window.webkitMediaStream
getUserMedia = navigator.mozGetUserMedia or navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.msGetUserMedia
URL = window.URL or window.webkitURL or window.msURL or window.oURL

browser = (if navigator.mozGetUserMedia then 'firefox' else 'chrome')
supported = (PeerConnection? and getUserMedia?)

# scope bind hax
getUserMedia = getUserMedia.bind navigator

processSDP = (sdp) ->
  return sdp unless browser is 'firefox'
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
  return el

shim = ->
  return unless supported # no need to shim
  if browser is 'firefox'
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
    unless MediaStream::getVideoTracks
      MediaStream::getVideoTracks = -> @videoTracks
      MediaStream::getAudioTracks = -> @audioTracks

    unless PeerConnection::getLocalStreams
      PeerConnection::getLocalStreams = -> @localStreams
      PeerConnection::getRemoteStreams = -> @remoteStreams

  out = 
    PeerConnection: PeerConnection
    IceCandidate: IceCandidate
    SessionDescription: SessionDescription
    MediaStream: MediaStream
    getUserMedia: getUserMedia
    URL: URL
    attachStream: attachStream
    processSDP: processSDP
    PeerConnConfig: PeerConnConfig
    browser: browser
    supported: supported
  return out

module.exports = shim()