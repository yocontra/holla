;(function(){

/**
 * Require the given path.
 *
 * @param {String} path
 * @return {Object} exports
 * @api public
 */

function require(path, parent, orig) {
  var resolved = require.resolve(path);

  // lookup failed
  if (null == resolved) {
    orig = orig || path;
    parent = parent || 'root';
    var err = new Error('Failed to require "' + orig + '" from "' + parent + '"');
    err.path = orig;
    err.parent = parent;
    err.require = true;
    throw err;
  }

  var module = require.modules[resolved];

  // perform real require()
  // by invoking the module's
  // registered function
  if (!module.exports) {
    module.exports = {};
    module.client = module.component = true;
    module.call(this, module.exports, require.relative(resolved), module);
  }

  return module.exports;
}

/**
 * Registered modules.
 */

require.modules = {};

/**
 * Registered aliases.
 */

require.aliases = {};

/**
 * Resolve `path`.
 *
 * Lookup:
 *
 *   - PATH/index.js
 *   - PATH.js
 *   - PATH
 *
 * @param {String} path
 * @return {String} path or null
 * @api private
 */

require.resolve = function(path) {
  if (path.charAt(0) === '/') path = path.slice(1);

  var paths = [
    path,
    path + '.js',
    path + '.json',
    path + '/index.js',
    path + '/index.json'
  ];

  for (var i = 0; i < paths.length; i++) {
    var path = paths[i];
    if (require.modules.hasOwnProperty(path)) return path;
    if (require.aliases.hasOwnProperty(path)) return require.aliases[path];
  }
};

/**
 * Normalize `path` relative to the current path.
 *
 * @param {String} curr
 * @param {String} path
 * @return {String}
 * @api private
 */

require.normalize = function(curr, path) {
  var segs = [];

  if ('.' != path.charAt(0)) return path;

  curr = curr.split('/');
  path = path.split('/');

  for (var i = 0; i < path.length; ++i) {
    if ('..' == path[i]) {
      curr.pop();
    } else if ('.' != path[i] && '' != path[i]) {
      segs.push(path[i]);
    }
  }

  return curr.concat(segs).join('/');
};

/**
 * Register module at `path` with callback `definition`.
 *
 * @param {String} path
 * @param {Function} definition
 * @api private
 */

require.register = function(path, definition) {
  require.modules[path] = definition;
};

/**
 * Alias a module definition.
 *
 * @param {String} from
 * @param {String} to
 * @api private
 */

require.alias = function(from, to) {
  if (!require.modules.hasOwnProperty(from)) {
    throw new Error('Failed to alias "' + from + '", it does not exist');
  }
  require.aliases[to] = from;
};

/**
 * Return a require function relative to the `parent` path.
 *
 * @param {String} parent
 * @return {Function}
 * @api private
 */

require.relative = function(parent) {
  var p = require.normalize(parent, '..');

  /**
   * lastIndexOf helper.
   */

  function lastIndexOf(arr, obj) {
    var i = arr.length;
    while (i--) {
      if (arr[i] === obj) return i;
    }
    return -1;
  }

  /**
   * The relative require() itself.
   */

  function localRequire(path) {
    var resolved = localRequire.resolve(path);
    return require(resolved, parent, path);
  }

  /**
   * Resolve relative to the parent.
   */

  localRequire.resolve = function(path) {
    var c = path.charAt(0);
    if ('/' == c) return path.slice(1);
    if ('.' == c) return require.normalize(p, path);

    // resolve deps by returning
    // the dep in the nearest "deps"
    // directory
    var segs = parent.split('/');
    var i = lastIndexOf(segs, 'deps') + 1;
    if (!i) i = 0;
    path = segs.slice(0, i + 1).join('/') + '/deps/' + path;
    return path;
  };

  /**
   * Check if module is defined at `path`.
   */

  localRequire.exists = function(path) {
    return require.modules.hasOwnProperty(localRequire.resolve(path));
  };

  return localRequire;
};
require.register("component-indexof/index.js", function(exports, require, module){

var indexOf = [].indexOf;

module.exports = function(arr, obj){
  if (indexOf) return arr.indexOf(obj);
  for (var i = 0; i < arr.length; ++i) {
    if (arr[i] === obj) return i;
  }
  return -1;
};
});
require.register("component-emitter/index.js", function(exports, require, module){

/**
 * Module dependencies.
 */

var index = require('indexof');

/**
 * Expose `Emitter`.
 */

module.exports = Emitter;

/**
 * Initialize a new `Emitter`.
 *
 * @api public
 */

function Emitter(obj) {
  if (obj) return mixin(obj);
};

/**
 * Mixin the emitter properties.
 *
 * @param {Object} obj
 * @return {Object}
 * @api private
 */

function mixin(obj) {
  for (var key in Emitter.prototype) {
    obj[key] = Emitter.prototype[key];
  }
  return obj;
}

/**
 * Listen on the given `event` with `fn`.
 *
 * @param {String} event
 * @param {Function} fn
 * @return {Emitter}
 * @api public
 */

Emitter.prototype.on = function(event, fn){
  this._callbacks = this._callbacks || {};
  (this._callbacks[event] = this._callbacks[event] || [])
    .push(fn);
  return this;
};

/**
 * Adds an `event` listener that will be invoked a single
 * time then automatically removed.
 *
 * @param {String} event
 * @param {Function} fn
 * @return {Emitter}
 * @api public
 */

Emitter.prototype.once = function(event, fn){
  var self = this;
  this._callbacks = this._callbacks || {};

  function on() {
    self.off(event, on);
    fn.apply(this, arguments);
  }

  fn._off = on;
  this.on(event, on);
  return this;
};

/**
 * Remove the given callback for `event` or all
 * registered callbacks.
 *
 * @param {String} event
 * @param {Function} fn
 * @return {Emitter}
 * @api public
 */

Emitter.prototype.off =
Emitter.prototype.removeListener =
Emitter.prototype.removeAllListeners = function(event, fn){
  this._callbacks = this._callbacks || {};

  // all
  if (0 == arguments.length) {
    this._callbacks = {};
    return this;
  }

  // specific event
  var callbacks = this._callbacks[event];
  if (!callbacks) return this;

  // remove all handlers
  if (1 == arguments.length) {
    delete this._callbacks[event];
    return this;
  }

  // remove specific handler
  var i = index(callbacks, fn._off || fn);
  if (~i) callbacks.splice(i, 1);
  return this;
};

/**
 * Emit `event` with the given args.
 *
 * @param {String} event
 * @param {Mixed} ...
 * @return {Emitter}
 */

Emitter.prototype.emit = function(event){
  this._callbacks = this._callbacks || {};
  var args = [].slice.call(arguments, 1)
    , callbacks = this._callbacks[event];

  if (callbacks) {
    callbacks = callbacks.slice(0);
    for (var i = 0, len = callbacks.length; i < len; ++i) {
      callbacks[i].apply(this, args);
    }
  }

  return this;
};

/**
 * Return array of callbacks for `event`.
 *
 * @param {String} event
 * @return {Array}
 * @api public
 */

Emitter.prototype.listeners = function(event){
  this._callbacks = this._callbacks || {};
  return this._callbacks[event] || [];
};

/**
 * Check if this emitter has `event` handlers.
 *
 * @param {String} event
 * @return {Boolean}
 * @api public
 */

Emitter.prototype.hasListeners = function(event){
  return !! this.listeners(event).length;
};

});
require.register("holla/dist/holla.js", function(exports, require, module){
// Generated by CoffeeScript 1.6.3
(function() {
  var Call, Client, holla, shims;

  Client = require('./Client');

  Call = require('./Call');

  shims = require('./shims');

  holla = {
    createClient: function(opt) {
      if (opt == null) {
        opt = {};
      }
      return new Client(opt);
    },
    Call: Call,
    Client: Client,
    shims: shims,
    supported: shims.supported,
    config: shims.PeerConnConfig,
    createStream: function(opt, cb) {
      var err, succ;
      if (shims.getUserMedia == null) {
        return cb("Missing getUserMedia");
      }
      err = cb;
      succ = function(s) {
        return cb(null, s);
      };
      shims.getUserMedia(opt, succ, err);
      return holla;
    },
    createFullStream: function(cb) {
      return holla.createStream({
        video: true,
        audio: true
      }, cb);
    },
    createVideoStream: function(cb) {
      return holla.createStream({
        video: true,
        audio: false
      }, cb);
    },
    createAudioStream: function(cb) {
      return holla.createStream({
        video: false,
        audio: true
      }, cb);
    }
  };

  module.exports = holla;

}).call(this);

});
require.register("holla/dist/Client.js", function(exports, require, module){
// Generated by CoffeeScript 1.6.3
(function() {
  var Call, Client, Emitter, socketio,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Emitter = require('emitter');

  socketio = io;

  Call = require('./Call');

  Client = (function(_super) {
    __extends(Client, _super);

    function Client(options) {
      var _this = this;
      this.options = options != null ? options : {};
      this.io = socketio.connect(this.options.host);
      this.io.on('reconnect', function() {
        return _this.emit('reconnect');
      });
      this.io.on('disconnect', function() {
        return _this.emit('disconnect');
      });
      this.io.on('error', function(err) {
        return _this.emit('error', err);
      });
      this.io.on('callRequest', function(callInfo) {
        var call;
        call = new Call(_this, callInfo.id, callInfo.caller);
        return _this.emit("call", call);
      });
      this.io.on('presenceChange', function(user, status) {
        return _this.emit('presence', user, status);
      });
    }

    Client.prototype.createCall = function(cb) {
      var _this = this;
      this.io.emit('createCall', function(err, id) {
        var call;
        if (err != null) {
          return cb(err);
        }
        call = new Call(_this, id);
        return cb(null, call);
      });
      return this;
    };

    Client.prototype.register = function(name, cb) {
      return this.io.emit('register', name, cb);
    };

    Client.prototype.unregister = function(cb) {
      return this.io.emit('unregister', cb);
    };

    return Client;

  })(Emitter);

  module.exports = Client;

}).call(this);

});
require.register("holla/dist/Call.js", function(exports, require, module){
// Generated by CoffeeScript 1.6.3
(function() {
  var Call, Emitter, User,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  User = require('./User');

  Emitter = require('emitter');

  Call = (function(_super) {
    __extends(Call, _super);

    function Call(client, id, callerName) {
      var _this = this;
      this.client = client;
      this.id = id;
      this._removeUser = __bind(this._removeUser, this);
      this._addNewUser = __bind(this._addNewUser, this);
      this._add = __bind(this._add, this);
      this._handleUserResponse = __bind(this._handleUserResponse, this);
      this.unmute = __bind(this.unmute, this);
      this.mute = __bind(this.mute, this);
      this.empty = __bind(this.empty, this);
      this.end = __bind(this.end, this);
      this.releaseLocalStream = __bind(this.releaseLocalStream, this);
      this.setLocalStream = __bind(this.setLocalStream, this);
      this.add = __bind(this.add, this);
      this.decline = __bind(this.decline, this);
      this.answer = __bind(this.answer, this);
      this._users = {};
      if (callerName) {
        this._add(callerName);
        this.caller = this.user(callerName);
      }
      this.client.io.on("" + this.id + ":end", function() {
        _this.empty();
        return _this.emit("end");
      });
      this.client.io.on("" + this.id + ":userAdded", this._addNewUser);
    }

    Call.prototype.answer = function() {
      if (!this.localStream) {
        throw new Error("Must call setLocalStream first");
      }
      this.client.io.emit("" + this.id + ":callResponse", true);
      this.client.emit("callAnswered", this);
      this.caller.createConnection();
      this.caller.addLocalStream(this.localStream);
      this.caller.once("sdp", this.caller.sendAnswer);
      return this;
    };

    Call.prototype.decline = function() {
      this.client.io.emit("" + this.id + ":callResponse", false);
      this.client.emit("callDeclined", this);
      return this;
    };

    Call.prototype.add = function(name) {
      if (!this.localStream) {
        throw new Error("Must call setLocalStream first");
      }
      this._add(name);
      this.client.io.emit("addUser", this.id, name, this._handleUserResponse(this.user(name)));
      return this.user(name);
    };

    Call.prototype.user = function(name) {
      return this._users[name];
    };

    Call.prototype.users = function() {
      return this._users;
    };

    Call.prototype.setLocalStream = function(stream) {
      this.localStream = stream;
      return this;
    };

    Call.prototype.releaseLocalStream = function() {
      var _ref;
      if ((_ref = this.localStream) != null) {
        _ref.stop();
      }
      delete this.localStream;
      return this;
    };

    Call.prototype.end = function() {
      var _this = this;
      this.client.io.emit("endCall", this.id, function(err) {
        if (err != null) {
          return _this.emit("error", err);
        }
      });
      return this;
    };

    Call.prototype.empty = function() {
      var name, user, _i, _len, _ref;
      _ref = this.users();
      for (user = _i = 0, _len = _ref.length; _i < _len; user = ++_i) {
        name = _ref[user];
        this._removeUser(user);
      }
      return this;
    };

    Call.prototype.mute = function() {
      var track, _i, _len, _ref;
      if (!this.localStream) {
        throw new Error("Must call setLocalStream first");
      }
      _ref = this.localStream.getAudioTracks();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        track = _ref[_i];
        track.enabled = false;
      }
      return this;
    };

    Call.prototype.unmute = function() {
      var track, _i, _len, _ref;
      if (!this.localStream) {
        throw new Error("Must call setLocalStream first");
      }
      _ref = this.localStream.getAudioTracks();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        track = _ref[_i];
        track.enabled = true;
      }
      return this;
    };

    Call.prototype._handleUserResponse = function(user) {
      var _this = this;
      return function(err) {
        if (err != null) {
          if (err === "Call declined") {
            user.accepted = false;
            user.emit("declined");
            _this.emit("userDeclined", user);
          } else {
            user.emit("error", err);
            _this.emit("error", err);
          }
        } else {
          user.accepted = true;
          user.emit("answered");
          _this.emit("userAnswered", user);
        }
        return _this;
      };
    };

    Call.prototype._add = function(name) {
      var _base;
      if ((_base = this._users)[name] == null) {
        _base[name] = new User(this, name);
      }
      return this;
    };

    Call.prototype._addNewUser = function(name) {
      var user;
      this._add(name);
      user = this.user(name);
      user.createConnection();
      user.addLocalStream(this.localStream);
      user.sendOffer();
      return this;
    };

    Call.prototype._removeUser = function(name) {
      var user;
      user = this.user(name);
      user.closeConnection();
      delete this._users[name];
      return this;
    };

    return Call;

  })(Emitter);

  module.exports = Call;

}).call(this);

});
require.register("holla/dist/User.js", function(exports, require, module){
// Generated by CoffeeScript 1.6.3
(function() {
  var Channel, Emitter, User, shims,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  shims = require('./shims');

  Emitter = require('emitter');

  Channel = require('./Channel');

  User = (function(_super) {
    __extends(User, _super);

    User.prototype.connection = null;

    function User(call, name) {
      this.call = call;
      this.name = name;
      this._handleRemoteCandidate = __bind(this._handleRemoteCandidate, this);
      this._handleRemoteSDP = __bind(this._handleRemoteSDP, this);
      this._handleError = __bind(this._handleError, this);
      this.createConnection();
      this.call.client.io.on("" + call.id + ":" + name + ":sdp", this._handleRemoteSDP);
      this.call.client.io.on("" + call.id + ":" + name + ":candidate", this._handleRemoteCandidate);
    }

    User.prototype.createConnection = function() {
      var _this = this;
      this.channels = {};
      this.connection = new shims.PeerConnection(shims.PeerConnConfig, shims.constraints);
      this.connection.onconnecting = function() {
        return _this.emit("connecting");
      };
      this.connection.onopen = function() {
        return _this.emit("connected");
      };
      this.connection.onicecandidate = function(evt) {
        if ((evt != null ? evt.candidate : void 0) != null) {
          return _this.sendCandidate(evt.candidate);
        }
      };
      this.connection.onaddstream = function(evt) {
        return _this.addStream(evt.stream);
      };
      this.connection.onremovestream = function(evt) {
        return _this.removeStream();
      };
      this.connection.oniceconnectionstatechange = this.connection.onicechange = function() {
        if (_this.connection.iceConnectionState === 'disconnected') {
          return _this.closeConnection();
        }
      };
      this.connection.ondatachannel = function(evt) {
        var chan;
        chan = evt.channel;
        _this.channels[chan.label] = new Channel(_this.connection, chan.label).setChannel(chan);
        return _this.emit('data:#{chan.label}', _this.channels[chan.label]);
      };
      return this;
    };

    User.prototype.closeConnection = function() {
      var chan, name, _ref;
      if (this.connection == null) {
        return this;
      }
      _ref = this.channels;
      for (name in _ref) {
        chan = _ref[name];
        chan.end();
      }
      this.connection.close();
      this.connection = null;
      this.channels = null;
      this.emit('disconnected');
      return this;
    };

    User.prototype.addLocalStream = function(stream) {
      this.connection.addStream(stream);
      return this;
    };

    User.prototype.addStream = function(stream) {
      this._ready = true;
      this.stream = stream;
      this.emit("ready", this.stream);
      return this;
    };

    User.prototype.removeStream = function() {
      this.closeConnection();
      return this;
    };

    User.prototype.ready = function(fn) {
      if (this._ready) {
        fn(this.stream);
      } else {
        this.once('ready', fn);
      }
      return this;
    };

    User.prototype.channel = function(name) {
      if (this.channels[name] == null) {
        this.channels[name] = new Channel(this.connection, name);
        this.emit('data:#{name}', this.channels[name]);
      }
      return this.channels[name];
    };

    User.prototype.sendCandidate = function(candidate) {
      return this.call.client.io.emit("sendCandidate", this.call.id, this.name, candidate, this._handleError);
    };

    User.prototype.sendOffer = function() {
      var done, err,
        _this = this;
      done = function(desc) {
        _this.connection.setLocalDescription(desc);
        desc.sdp = shims.processSDPOut(desc.sdp);
        return _this.call.client.io.emit("sendSDPOffer", _this.call.id, _this.name, desc, _this._handleError);
      };
      err = function(e) {
        return _this.emit("error", e);
      };
      this.connection.createOffer(done, err, shims.constraints);
      return this;
    };

    User.prototype.sendAnswer = function() {
      var done,
        _this = this;
      done = function(desc) {
        desc.sdp = shims.processSDPOut(desc.sdp);
        _this.connection.setLocalDescription(desc);
        return _this.call.client.io.emit("sendSDPAnswer", _this.call.id, _this.name, desc, _this._handleError);
      };
      this.connection.createAnswer(done, this._handleError, shims.constraints);
      return this;
    };

    User.prototype._handleError = function(e) {
      if (e != null) {
        return this.emit("error", e);
      }
    };

    User.prototype._handleRemoteSDP = function(desc) {
      var succ,
        _this = this;
      desc.sdp = shims.processSDPIn(desc.sdp);
      succ = function() {
        return _this.emit("sdp");
      };
      this.connection.setRemoteDescription(new shims.SessionDescription(desc), succ, this._handleError);
      return this;
    };

    User.prototype._handleRemoteCandidate = function(candidate) {
      this.emit("candidate", candidate);
      this.connection.addIceCandidate(new shims.IceCandidate(candidate));
      return this;
    };

    return User;

  })(Emitter);

  module.exports = User;

}).call(this);

});
require.register("holla/dist/Channel.js", function(exports, require, module){
// Generated by CoffeeScript 1.6.3
(function() {
  var Channel, Emitter,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Emitter = require('emitter');

  Channel = (function(_super) {
    __extends(Channel, _super);

    Channel.prototype.open = false;

    function Channel(connection, name) {
      this.connection = connection;
      this.name = name;
      this.end = __bind(this.end, this);
      this.send = __bind(this.send, this);
      this.connect = __bind(this.connect, this);
      this.setChannel = __bind(this.setChannel, this);
      this.options = {
        reliable: false
      };
    }

    Channel.prototype.setChannel = function(chan) {
      var _this = this;
      this.dc = chan;
      this.dc.onopen = function() {
        _this.open = true;
        return _this.emit('open');
      };
      this.dc.onclose = function() {
        _this.open = false;
        return _this.emit('end');
      };
      this.dc.onmessage = function(e) {
        return _this.emit('data', JSON.parse(e.data));
      };
      return this;
    };

    Channel.prototype.connect = function() {
      this.setChannel(this.connection.createDataChannel(this.name, this.options));
      return this;
    };

    Channel.prototype.send = function(data) {
      if (this.open) {
        this.dc.send(JSON.stringify(data));
      }
      return this;
    };

    Channel.prototype.end = function() {
      if (this.open) {
        this.dc.close();
      }
      return this;
    };

    return Channel;

  })(Emitter);

  module.exports = Channel;

}).call(this);

});
require.register("holla/dist/shims.js", function(exports, require, module){
// Generated by CoffeeScript 1.6.3
(function() {
  var IceCandidate, MediaStream, PeerConnConfig, PeerConnection, SessionDescription, URL, attachStream, browser, getUserMedia, mediaConstraints, processSDPIn, processSDPOut, supported;

  PeerConnection = window.PeerConnection || window.webkitPeerConnection00 || window.webkitRTCPeerConnection;

  IceCandidate = window.RTCIceCandidate;

  SessionDescription = window.RTCSessionDescription;

  MediaStream = window.MediaStream || window.webkitMediaStream;

  getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia;

  URL = window.URL || window.webkitURL;

  if (getUserMedia != null) {
    getUserMedia = getUserMedia.bind(navigator);
  }

  browser = (navigator.mozGetUserMedia ? 'firefox' : 'chrome');

  supported = (PeerConnection != null) && (getUserMedia != null);

  processSDPOut = function(sdp) {
    return sdp;
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

  if (supported) {
    PeerConnConfig = {
      iceServers: [
        {
          url: "stun:stun.l.google.com:19302"
        }, {
          url: "stun:stun1.l.google.com:19302"
        }, {
          url: "stun:stun2.l.google.com:19302"
        }, {
          url: "stun:stun3.l.google.com:19302"
        }, {
          url: "stun:stun4.l.google.com:19302"
        }
      ]
    };
    mediaConstraints = {
      optional: [
        {
          DtlsSrtpKeyAgreement: true
        }, {
          RtpDataChannels: true
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
    MediaStream.prototype.pipe = function(el) {
      var uri;
      uri = URL.createObjectURL(this);
      attachStream(uri, el);
      return this;
    };
  }

  module.exports = {
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
    constraints: mediaConstraints
  };

}).call(this);

});
require.alias("component-emitter/index.js", "holla/deps/emitter/index.js");
require.alias("component-emitter/index.js", "emitter/index.js");
require.alias("component-indexof/index.js", "component-emitter/deps/indexof/index.js");

require.alias("holla/dist/holla.js", "holla/index.js");

if (typeof exports == "object") {
  module.exports = require("holla");
} else if (typeof define == "function" && define.amd) {
  define(function(){ return require("holla"); });
} else {
  this["holla"] = require("holla");
}})();