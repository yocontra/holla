var vein = Vein.createClient();

vein.on('ready', function(services) {
  console.log("Connected - Available services: " + services);
  return vein.add(1, 2, 3, 4, function(res) {
    return console.log(res);
  });
});
