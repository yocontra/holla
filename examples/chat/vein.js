(function() {
  var Vein, cookies,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = Array.prototype.slice;

  cookies = {
    getItem: function(key) {
      if (!cookies.hasItem(key)) return;
      return unescape(document.cookie.replace(new RegExp("(?:^|.*;\\s*)" + escape(key).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*"), "$1"));
    },
    setItem: function(key, val, expires) {
      var sExpires;
      sExpires = "";
      if (typeof expires === 'number') sExpires = "; max-age=" + expires;
      if (typeof expires === 'string') sExpires = "; expires=" + expires;
      if (typeof expires === 'object' ? expires.toGMTString : void 0) {
        sExpires = "; expires=" + (expires.toGMTString());
      }
      document.cookie = "" + (escape(key)) + "=" + (escape(val)) + sExpires;
    },
    removeItem: function(key) {
      document.cookie = "" + (escape(key)) + "=; expires=Thu, 01-Jan-1970 00:00:01 GMT; path=/";
    },
    hasItem: function(key) {
      var ep;
      ep = new RegExp("(?:^|;\\s*)" + (escape(key).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\="));
      return ep.test(document.cookie);
    }
  };

  Vein = (function() {

    function Vein(options) {
      var _base, _base2, _base3;
      this.options = options != null ? options : {};
      this.getSender = __bind(this.getSender, this);
      this.getListener = __bind(this.getListener, this);
      this.handleMethods = __bind(this.handleMethods, this);
      this.handleMessage = __bind(this.handleMessage, this);
      this.handleClose = __bind(this.handleClose, this);
      this.clearSession = __bind(this.clearSession, this);
      this.setSession = __bind(this.setSession, this);
      this.getSession = __bind(this.getSession, this);
      if ((_base = this.options).prefix == null) _base.prefix = 'vein';
      if ((_base2 = this.options).host == null) _base2.host = location.origin;
      if ((_base3 = this.options).sessionName == null) {
        _base3.sessionName = "VEINSESSID-" + this.options.prefix;
      }
      this.socket = new SockJS("" + this.options.host + "/" + this.options.prefix, null, this.options);
      this.callbacks['methods'] = this.handleMethods;
      this.callbacks['session'] = this.setSession;
      this.socket.onmessage = this.handleMessage;
      this.socket.onclose = this.handleClose;
      return;
    }

    Vein.prototype.callbacks = {};

    Vein.prototype.subscribe = {};

    Vein.prototype.getSession = function() {
      return cookies.getItem(this.options.sessionName);
    };

    Vein.prototype.setSession = function(sess) {
      cookies.setItem(this.options.sessionName, sess, this.options.sessionLength);
      return true;
    };

    Vein.prototype.clearSession = function() {
      cookies.removeItem(this.options.sessionName);
    };

    Vein.prototype.ready = function(cb) {
      return this.callbacks['ready'] = cb;
    };

    Vein.prototype.close = function(cb) {
      return this.callbacks['close'] = cb;
    };

    Vein.prototype.handleClose = function() {
      var _base;
      return typeof (_base = this.callbacks)['close'] === "function" ? _base['close']() : void 0;
    };

    Vein.prototype.handleMessage = function(e) {
      var err, fn, id, keep, method, params, _i, _len, _ref, _ref2, _ref3;
      _ref = JSON.parse(e.data), id = _ref.id, method = _ref.method, params = _ref.params, err = _ref.err;
      if (!Array.isArray(params)) params = [params];
      if (this.subscribe[method] && this.subscribe[method].listeners) {
        _ref2 = this.subscribe[method].listeners;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          fn = _ref2[_i];
          fn.apply(null, params);
        }
      }
      if (!this.callbacks[id]) return;
      keep = (_ref3 = this.callbacks)[id].apply(_ref3, params);
      if (keep !== true) delete this.callbacks[id];
    };

    Vein.prototype.handleMethods = function() {
      var method, methods, _base, _i, _j, _len, _len2;
      methods = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      for (_i = 0, _len = methods.length; _i < _len; _i++) {
        method = methods[_i];
        this[method] = this.getSender(method);
      }
      for (_j = 0, _len2 = methods.length; _j < _len2; _j++) {
        method = methods[_j];
        this.subscribe[method] = this.getListener(method);
      }
      if (typeof (_base = this.callbacks)['ready'] === "function") {
        _base['ready'](methods);
      }
      delete this.callbacks['ready'];
    };

    Vein.prototype.getListener = function(method) {
      var _this = this;
      return function(cb) {
        var _base;
        if ((_base = _this.subscribe[method]).listeners == null) {
          _base.listeners = [];
        }
        _this.subscribe[method].listeners.push(cb);
      };
    };

    Vein.prototype.getSender = function(method) {
      var _this = this;
      return function() {
        var cb, id, params, _i;
        params = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
        id = _this.getId();
        _this.callbacks[id] = cb;
        _this.socket.send(JSON.stringify({
          id: id,
          method: method,
          params: params,
          session: _this.getSession()
        }));
      };
    };

    Vein.prototype.getId = function() {
      var rand;
      rand = function() {
        return (((1 + Math.random()) * 0x10000000) | 0).toString(16);
      };
      return rand() + rand() + rand();
    };

    return Vein;

  })();

  if (typeof define === 'function') {
    define(function() {
      return Vein;
    });
  } else {
    window.Vein = Vein;
  }

}).call(this);
