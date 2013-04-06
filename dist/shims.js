// Generated by CoffeeScript 1.6.2
(function() {
  var IceCandidate, MediaStream, PeerConnection, SessionDescription, URL, attachStream, browser, extract, getUserMedia, loadBlob, processSDPIn, processSDPOut, recordVideo, removeCN, replaceCodec, saveBlob, shim, supported, useOPUS;

  PeerConnection = window.mozRTCPeerConnection || window.PeerConnection || window.webkitPeerConnection00 || window.webkitRTCPeerConnection;

  IceCandidate = window.mozRTCIceCandidate || window.RTCIceCandidate;

  SessionDescription = window.mozRTCSessionDescription || window.RTCSessionDescription;

  MediaStream = window.MediaStream || window.webkitMediaStream;

  getUserMedia = navigator.mozGetUserMedia || navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.msGetUserMedia;

  URL = window.URL || window.webkitURL || window.msURL || window.oURL;

  getUserMedia = getUserMedia.bind(navigator);

  browser = (navigator.mozGetUserMedia ? 'firefox' : 'chrome');

  supported = (PeerConnection != null) && (getUserMedia != null);

  extract = function(str, reg) {
    var match;

    match = str.match(reg);
    return (match != null ? match[1] : null);
  };

  replaceCodec = function(line, codec) {
    var el, els, idx, out, _i, _len;

    els = line.split(' ');
    out = [];
    for (idx = _i = 0, _len = els.length; _i < _len; idx = ++_i) {
      el = els[idx];
      if (idx === 3) {
        out[idx++] = codec;
      }
      if (el !== codec) {
        out[idx++] = el;
      }
    }
    return out.join(' ');
  };

  removeCN = function(lines, mLineIdx) {
    var cnPos, idx, line, mLineEls, payload, _i, _len;

    mLineEls = lines[mLineIdx].split(' ');
    for (idx = _i = 0, _len = lines.length; _i < _len; idx = ++_i) {
      line = lines[idx];
      if (!(line != null)) {
        continue;
      }
      payload = extract(line, /a=rtpmap:(\d+) CN\/\d+/i);
      if (payload != null) {
        cnPos = mLineEls.indexOf(payload);
        if (cnPos !== -1) {
          mLineEls.splice(cnPos, 1);
        }
        lines.splice(idx, 1);
      }
    }
    lines[mLineIdx] = mLineEls.join(' ');
    return lines;
  };

  useOPUS = function(sdp) {
    var idx, line, lines, mLineIdx, payload, _i, _len;

    lines = sdp.split('\r\n');
    mLineIdx = ((function() {
      var _i, _len, _results;

      _results = [];
      for (idx = _i = 0, _len = lines.length; _i < _len; idx = ++_i) {
        line = lines[idx];
        if (line.indexOf('m=audio') !== -1) {
          _results.push(idx);
        }
      }
      return _results;
    })())[0];
    if (mLineIdx == null) {
      return sdp;
    }
    for (idx = _i = 0, _len = lines.length; _i < _len; idx = ++_i) {
      line = lines[idx];
      if (!(line.indexOf('opus/48000') !== -1)) {
        continue;
      }
      payload = extract(line, /:(\d+) opus\/48000/i);
      if (payload != null) {
        lines[mLineIdx] = replaceCodec(lines[mLineIdx], payload);
      }
      break;
    }
    lines = removeCN(lines, mLineIdx);
    return lines.join('\r\n');
  };

  processSDPOut = function(sdp) {
    var addCrypto, line, out, _i, _j, _len, _len1, _ref, _ref1;

    out = [];
    if (browser === 'firefox') {
      addCrypto = "a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:BAADBAADBAADBAADBAADBAADBAADBAADBAADBAAD";
      _ref = sdp.split('\r\n');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        out.push(line);
        if (line.indexOf('m=') === 0) {
          out.push(addCrypto);
        }
      }
    } else {
      _ref1 = sdp.split('\r\n');
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        line = _ref1[_j];
        if (line.indexOf("a=ice-options:google-ice") === -1) {
          out.push(line);
        }
      }
    }
    return useOPUS(out.join('\r\n'));
  };

  processSDPIn = function(sdp) {
    return sdp;
  };

  attachStream = function(uri, el) {
    var e, _i, _len;

    if (typeof el === "string") {
      return attachStream(uri, document.getElementById(el));
    } else if (el.jquery) {
      el.attr('src', uri);
      for (_i = 0, _len = el.length; _i < _len; _i++) {
        e = el[_i];
        e.play();
      }
    } else {
      el.src = uri;
      el.play();
    }
    return el;
  };

  saveBlob = function(file, blob) {
    var evt, link;

    link = document.createElement("a");
    link.href = blob;
    link.target = "_blank";
    link.download = file;
    evt = document.createEvent("Event");
    evt.initEvent("click", true, true);
    link.dispatchEvent(evt);
    URL.revokeObjectURL(link.href);
  };

  loadBlob = function(blob, cb) {
    var reader;

    reader = new FileReader;
    reader.readAsDataURL(blob);
    return reader.onload = function(event) {
      return cb(event.target.result);
    };
  };

  recordVideo = function(el) {
    var can, ctrl, ctx, end, frames, getBlob, grab, h, requested, save, w;

    if (el.jquery) {
      h = el.height();
      w = el.width();
      el = el[0];
    } else {
      h = el.height;
      w = el.width;
    }
    can = document.createElement('canvas');
    ctx = can.getContext('2d');
    can.width = w;
    can.height = h;
    frames = [];
    grab = function() {
      var requested;

      requested = requestAnimationFrame(grab);
      ctx.drawImage(el, 0, 0, w, h);
      frames.push(can.toDataURL('image/webp', 1));
    };
    getBlob = function(cb) {
      var blob;

      blob = Whammy.fromImageArray(frames, 1000 / 60);
      loadBlob(blob, cb);
      return ctrl;
    };
    save = function(file) {
      if (file == null) {
        file = "recording.webp";
      }
      getBlob(function(blob) {
        return saveBlob(file, blob);
      });
      return ctrl;
    };
    end = function(cb) {
      cancelAnimationFrame(requested);
      return ctrl;
    };
    requested = requestAnimationFrame(grab);
    ctrl = {
      save: save,
      getBlob: getBlob,
      end: end
    };
    return ctrl;
  };

  shim = function() {
    var PeerConnConfig, mediaConstraints, out;

    if (!supported) {
      return;
    }
    if (browser === 'firefox') {
      PeerConnConfig = {
        iceServers: [
          {
            url: "stun:23.21.150.121"
          }
        ]
      };
      mediaConstraints = {
        mandatory: {
          OfferToReceiveAudio: true,
          OfferToReceiveVideo: true,
          MozDontOfferDataChannel: true
        }
      };
      MediaStream.prototype.getVideoTracks = function() {
        return [];
      };
      MediaStream.prototype.getAudioTracks = function() {
        return [];
      };
    } else {
      PeerConnConfig = {
        iceServers: [
          {
            url: "stun:stun.l.google.com:19302"
          }
        ]
      };
      mediaConstraints = {
        mandatory: {
          OfferToReceiveAudio: true,
          OfferToReceiveVideo: true
        },
        optional: [
          {
            DtlsSrtpKeyAgreement: true
          }
        ]
      };
      if (!MediaStream.prototype.getVideoTracks) {
        MediaStream.prototype.getVideoTracks = function() {
          return this.videoTracks;
        };
        MediaStream.prototype.getAudioTracks = function() {
          return this.audioTracks;
        };
      }
      if (!PeerConnection.prototype.getLocalStreams) {
        PeerConnection.prototype.getLocalStreams = function() {
          return this.localStreams;
        };
        PeerConnection.prototype.getRemoteStreams = function() {
          return this.remoteStreams;
        };
      }
    }
    out = {
      PeerConnection: PeerConnection,
      IceCandidate: IceCandidate,
      SessionDescription: SessionDescription,
      MediaStream: MediaStream,
      getUserMedia: getUserMedia,
      URL: URL,
      attachStream: attachStream,
      processSDPIn: processSDPIn,
      processSDPOut: processSDPOut,
      PeerConnConfig: PeerConnConfig,
      browser: browser,
      supported: supported,
      constraints: mediaConstraints,
      recordVideo: recordVideo,
      loadBlob: loadBlob,
      saveBlob: saveBlob
    };
    return out;
  };

  
(function() {
    var lastTime = 0;
    var vendors = ['ms', 'moz', 'webkit', 'o'];
    for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
        window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
        window.cancelAnimationFrame =
          window[vendors[x]+'CancelAnimationFrame'] || window[vendors[x]+'CancelRequestAnimationFrame'];
    }

    if (!window.requestAnimationFrame)
        window.requestAnimationFrame = function(callback, element) {
            var currTime = new Date().getTime();
            var timeToCall = Math.max(0, 16 - (currTime - lastTime));
            var id = window.setTimeout(function() { callback(currTime + timeToCall); },
              timeToCall);
            lastTime = currTime + timeToCall;
            return id;
        };

    if (!window.cancelAnimationFrame)
        window.cancelAnimationFrame = function(id) {
            clearTimeout(id);
        };
}());
/* https://github.com/antimatter15/whammy */
var Whammy=function(){function g(a){for(var b=a[0].width,e=a[0].height,c=a[0].duration,d=1;d<a.length;d++){if(a[d].width!=b)throw"Frame "+(d+1)+" has a different width";if(a[d].height!=e)throw"Frame "+(d+1)+" has a different height";if(0>a[d].duration)throw"Frame "+(d+1)+" has a weird duration";c+=a[d].duration}var f=0,a=[{id:440786851,data:[{data:1,id:17030},{data:1,id:17143},{data:4,id:17138},{data:8,id:17139},{data:"webm",id:17026},{data:2,id:17031},{data:2,id:17029}]},{id:408125543,data:[{id:357149030,
data:[{data:1E6,id:2807729},{data:"whammy",id:19840},{data:"whammy",id:22337},{data:[].slice.call(new Uint8Array((new Float64Array([c])).buffer),0).map(function(a){return String.fromCharCode(a)}).reverse().join(""),id:17545}]},{id:374648427,data:[{id:174,data:[{data:1,id:215},{data:1,id:25541},{data:0,id:156},{data:"und",id:2274716},{data:"V_VP8",id:134},{data:"VP8",id:2459272},{data:1,id:131},{id:224,data:[{data:b,id:176},{data:e,id:186}]}]}]},{id:524531317,data:[{data:0,id:231}].concat(a.map(function(a){var b;
b=a.data.slice(4);var c=Math.round(f);b=[129,c>>8,c&255,128].map(function(a){return String.fromCharCode(a)}).join("")+b;f+=a.duration;return{data:b,id:163}}))}]}];return j(a)}function m(a){for(var b=[];0<a;)b.push(a&255),a>>=8;return new Uint8Array(b.reverse())}function k(a){for(var b=[],a=(a.length%8?Array(9-a.length%8).join("0"):"")+a,e=0;e<a.length;e+=8)b.push(parseInt(a.substr(e,8),2));return new Uint8Array(b)}function j(a){for(var b=[],e=0;e<a.length;e++){var c=a[e].data;"object"==typeof c&&
(c=j(c));"number"==typeof c&&(c=k(c.toString(2)));if("string"==typeof c){for(var d=new Uint8Array(c.length),f=0;f<c.length;f++)d[f]=c.charCodeAt(f);c=d}f=c.size||c.byteLength;d=Math.ceil(Math.ceil(Math.log(f)/Math.log(2))/8);f=f.toString(2);f=Array(7*d+8-f.length).join("0")+f;d=Array(d).join("0")+"1"+f;b.push(m(a[e].id));b.push(k(d));b.push(c)}return new Blob(b,{type:"video/webm"})}function l(a){for(var b=a.RIFF[0].WEBP[0],e=b.indexOf("\u009d\u0001*"),c=0,d=[];4>c;c++)d[c]=b.charCodeAt(e+3+c);c=d[1]<<
8|d[0];e=c&16383;c=d[3]<<8|d[2];return{width:e,height:c&16383,data:b,riff:a}}function h(a){for(var b=0,e={};b<a.length;){var c=a.substr(b,4),d=parseInt(a.substr(b+4,4).split("").map(function(a){a=a.charCodeAt(0).toString(2);return Array(8-a.length+1).join("0")+a}).join(""),2),f=a.substr(b+4+4,d),b=b+(8+d);e[c]=e[c]||[];"RIFF"==c||"LIST"==c?e[c].push(h(f)):e[c].push(f)}return e}function i(a,b){this.frames=[];this.duration=1E3/a;this.quality=b||0.8}i.prototype.add=function(a,b){if("undefined"!=typeof b&&
this.duration)throw"you can't pass a duration if the fps is set";if("undefined"==typeof b&&!this.duration)throw"if you don't have the fps set, you ned to have durations here.";a.canvas&&(a=a.canvas);if(a.toDataURL)a=a.toDataURL("image/webp",this.quality);else if("string"!=typeof a)throw"frame must be a a HTMLCanvasElement, a CanvasRenderingContext2D or a DataURI formatted string";if(!/^data:image\/webp;base64,/ig.test(a))throw"Input must be formatted properly as a base64 encoded DataURI of type image/webp";
this.frames.push({image:a,duration:b||this.duration})};i.prototype.compile=function(){return new g(this.frames.map(function(a){var b=l(h(atob(a.image.slice(23))));b.duration=a.duration;return b}))};return{Video:i,fromImageArray:function(a,b){return g(a.map(function(a){a=l(h(atob(a.slice(23))));a.duration=1E3/b;return a}))},toWebM:g}}();
;

  module.exports = shim();

}).call(this);