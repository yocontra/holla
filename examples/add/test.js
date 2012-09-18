var vein = Vein.createClient();

vein.ready(function(services) {
  console.log("Connected - Available services: " + services);
  vein.add(1, 2, 3, 4, function(res) {
    return console.log(res);
  });
});
