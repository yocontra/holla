(function() {
  var Vein, cookies,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = Array.prototype.slice;

  cookies = {
    getItem: function(sKey) {
      if (!cookies.hasItem(sKey)) return;
      return unescape(document.cookie.replace(new RegExp("(?:^|.*;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*"), "$1"));
    },
    setItem: function(sKey, sValue, vEnd, sPath, sDomain, bSecure) {
      var sExpires;
      if (vEnd) {
        if (typeof vEnd === 'number') sExpires = "; max-age=" + vEnd;
        if (typeof vEnd === 'string') sExpires = "; expires=" + vEnd;
        if (typeof vEnd === 'object' ? vEnd.hasOwnProperty("toGMTString") : void 0) {
          sExpires = "; expires=" + (vEnd.toGMTString());
        }
      }
      sDomain = (sDomain ? "; domain=" + sDomain : "");
      sPath = (sPath ? "; path=" + sPath : "");
      sExpires = (sExpires ? sExpires : "");
      bSecure = (bSecure ? "; secure" : "");
      return document.cookie = "" + (escape(sKey)) + "=" + (escape(sValue)) + sExpires + sDomain + sPath + bSecure;
    },
    removeItem: function(sKey) {
      var oExpDate;
      if (!cookies.hasItem(sKey)) return;
      oExpDate = new Date();
      oExpDate.setDate(oExpDate.getDate() - 1);
      return document.cookie = "" + (escape(sKey)) + "=; expires=" + (oExpDate.toGMTString()) + "; path=/";
    },
    hasItem: function(sKey) {
      return (new RegExp("(?:^|;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test(document.cookie);
    }
  };

  Vein = (function() {

    function Vein(url, options) {
      var _base, _base2, _base3;
      this.url = url != null ? url : location.origin;
      this.options = options != null ? options : {};
      this.getSender = __bind(this.getSender, this);
      this.getListener = __bind(this.getListener, this);
      this.handleSession = __bind(this.handleSession, this);
      this.handleServices = __bind(this.handleServices, this);
      this.handleMessage = __bind(this.handleMessage, this);
      this.handleClose = __bind(this.handleClose, this);
      this.clearSession = __bind(this.clearSession, this);
      if ((_base = this.options).prefix == null) _base.prefix = 'vein';
      if ((_base2 = this.options).sessionName == null) {
        _base2.sessionName = "VEINSESSID-" + this.options.prefix;
      }
      if ((_base3 = this.options).sessionExpires == null) {
        _base3.sessionExpires = 1;
      }
      this.socket = new SockJS("" + this.url + "/" + this.options.prefix, null, this.options);
      this.callbacks['services'] = this.handleServices;
      this.callbacks['session'] = this.handleSession;
      this.socket.onmessage = this.handleMessage;
      this.socket.onclose = this.handleClose;
      this.session = this.cookie();
      return;
    }

    Vein.prototype.callbacks = {};

    Vein.prototype.subscribe = {};

    Vein.prototype.session = void 0;

    Vein.prototype.clearSession = function() {
      this.session = void 0;
      this.cookie('', true);
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
      var args, fn, id, keep, service, _i, _len, _ref, _ref2, _ref3;
      _ref = JSON.parse(e.data), id = _ref.id, service = _ref.service, args = _ref.args;
      if (this.subscribe[service] && this.subscribe[service].listeners) {
        _ref2 = this.subscribe[service].listeners;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          fn = _ref2[_i];
          fn.apply(null, args);
        }
      }
      if (!this.callbacks[id]) return;
      keep = (_ref3 = this.callbacks)[id].apply(_ref3, args);
      if (!keep) delete this.callbacks[id];
    };

    Vein.prototype.handleServices = function() {
      var service, services, _base, _i, _j, _len, _len2;
      services = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      for (_i = 0, _len = services.length; _i < _len; _i++) {
        service = services[_i];
        this[service] = this.getSender(service);
      }
      for (_j = 0, _len2 = services.length; _j < _len2; _j++) {
        service = services[_j];
        this.subscribe[service] = this.getListener(service);
      }
      if (typeof (_base = this.callbacks)['ready'] === "function") {
        _base['ready'](services);
      }
      delete this.callbacks['ready'];
    };

    Vein.prototype.handleSession = function(sess) {
      this.session = sess;
      this.cookie(sess);
      return true;
    };

    Vein.prototype.getListener = function(service) {
      var _this = this;
      return function(cb) {
        var _base;
        if ((_base = _this.subscribe[service]).listeners == null) {
          _base.listeners = [];
        }
        _this.subscribe[service].listeners.push(cb);
      };
    };

    Vein.prototype.getSender = function(service) {
      var _this = this;
      return function() {
        var args, cb, id, _i;
        args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
        id = _this.getId();
        _this.callbacks[id] = cb;
        _this.socket.send(JSON.stringify({
          id: id,
          service: service,
          args: args
        }));
      };
    };

    Vein.prototype.cookie = function(sess, del) {
      var name;
      name = this.options.sessionName;
      if (del) return cookies.removeItem(name);
      if (sess) {
        return cookies.setItem(name, sess, this.options.sessionExpires);
      } else {
        return cookies.getItem(name);
      }
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
