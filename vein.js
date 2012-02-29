var Vein, getId,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __slice = Array.prototype.slice;

getId = function() {
  var rand;
  rand = function() {
    return (((1 + Math.random()) * 0x10000) | 0).toString(16);
  };
  return "" + rand() + rand() + rand() + rand() + rand() + rand();
};

Vein = (function() {

  function Vein(url, options) {
    this.setup = __bind(this.setup, this);
    var _this = this;
    if (url == null) url = "http://" + location.host;
    this.socket = new SockJS("" + url + "/vein", null, options);
    this.callbacks['services'] = this.setup;
    this.socket.onmessage = function(e) {
      var args, id, _ref, _ref2;
      _ref = JSON.parse(e.data), id = _ref.id, args = _ref.args;
      if (!(id && _this.callbacks[id])) return;
      (_ref2 = _this.callbacks)[id].apply(_ref2, args);
      return delete _this.callbacks[id];
    };
    this.socket.onclose = function() {
      var _base;
      return typeof (_base = _this.callbacks)['close'] === "function" ? _base['close']() : void 0;
    };
    return;
  }

  Vein.prototype.ready = function(cb) {
    return this.callbacks['ready'] = cb;
  };

  Vein.prototype.close = function(cb) {
    return this.callbacks['close'] = cb;
  };

  Vein.prototype.setup = function() {
    var service, services, _base, _fn, _i, _len,
      _this = this;
    services = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    _fn = function(service) {
      return _this[service] = function() {
        var args, cb, id, _j;
        args = 2 <= arguments.length ? __slice.call(arguments, 0, _j = arguments.length - 1) : (_j = 0, []), cb = arguments[_j++];
        id = getId();
        this.callbacks[id] = cb;
        return this.socket.send(JSON.stringify({
          id: id,
          service: service,
          args: args
        }));
      };
    };
    for (_i = 0, _len = services.length; _i < _len; _i++) {
      service = services[_i];
      _fn(service);
    }
    if (typeof (_base = this.callbacks)['ready'] === "function") {
      _base['ready'](services);
    }
    delete this.callbacks['ready'];
    delete this.callbacks['services'];
  };

  Vein.prototype.callbacks = {};

  return Vein;

})();

window.Vein = Vein;

if (window.define != null) {
  window.define(["https://d1fxtkz8shb9d2.cloudfront.net/sockjs-0.2.js"], window.Vein);
}
