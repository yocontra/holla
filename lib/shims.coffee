# begin compatibility insanity

# First we deal with vendor prefixes
PeerConnection = window.PeerConnection or window.webkitPeerConnection00 or window.webkitRTCPeerConnection
IceCandidate = window.RTCIceCandidate
SessionDescription = window.RTCSessionDescription
MediaStream = window.MediaStream or window.webkitMediaStream
getUserMedia = navigator.getUserMedia or navigator.webkitGetUserMedia
URL = window.URL or window.webkitURL

# getUserMedia errors unless it is bound to the scope of navigator
if getUserMedia?
  getUserMedia = getUserMedia.bind navigator

# Very simple browser detection for chrome and FF
browser = (if navigator.mozGetUserMedia then 'firefox' else 'chrome')
supported = (PeerConnection? and getUserMedia?)

processSDPOut = (sdp) -> return sdp
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

if supported # no need to shim
  PeerConnConfig = 
    iceServers: [
      url: "stun:stun.l.google.com:19302"
    ,
      url: "stun:stun1.l.google.com:19302"
    ,
      url: "stun:stun2.l.google.com:19302"
    ,
      url: "stun:stun3.l.google.com:19302"
    ,
      url: "stun:stun4.l.google.com:19302"
    ]
  mediaConstraints =
    optional: [
        DtlsSrtpKeyAgreement: true
      ,
        RtpDataChannels: true
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

module.exports =
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
