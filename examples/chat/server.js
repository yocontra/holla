(function() {
  var Vein, app, checkUser, connect, join, server, users, vein;

  join = require('path').join;

  connect = require("connect");

  Vein = require("../../index.js");

  app = connect();

  app.use(connect.static(__dirname));

  server = app.listen(8080);

  users = {};

  checkUser = function(name, socket) {
    return users[name] && users[name].id === socket.id;
  };

  vein = new Vein(server);

  vein.add('join', function(send, socket, name) {
    if (!name) return;
    if (!(typeof name === 'string' && name.length > 0 && name.length < 10)) {
      return send({
        error: 'Invalid name'
      });
    }
    if (users[name] && vein.clients.indexOf(users[name]) > -1) {
      return send({
        error: 'Name already in use'
      });
    }
    users[name] = socket;
    return send.all(name, Object.keys(users));
  });

  vein.add('leave', function(send, socket, name) {
    if (!name) return;
    if (!checkUser(name, socket)) {
      return send({
        error: 'Not authorized'
      });
    }
    delete users[name];
    return send.all(name, Object.keys(users));
  });

  vein.add('message', function(send, socket, name, message) {
    if (!(name && message)) return;
    if (!checkUser(name, socket)) {
      return send({
        error: 'Not authorized'
      });
    }
    if (!(typeof message === 'string' && message.length > -1 && message.length < 750)) {
      return send({
        error: 'Invalid message'
      });
    }
    message = message.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    return send.all(name, message);
  });

  console.log("Server listening");

}).call(this);
