var BlendMicro = require(__dirname+'/../');
// var BlendMicro = require('blendmicro');

blendmicro = new BlendMicro("BlendMicro");

blendmicro.on('open', function(){
  console.log("open!!");

  setInterval(function(){
    blendmicro.write("test"); // write data
  }, 500);

  blendmicro.on("data", function(data){ // read data
    console.log(data.toString());
  });

});
