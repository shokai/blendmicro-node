var BlendMicro = require(__dirname+'/../');
// var BlendMicro = require('blendmicro');

var bm = new BlendMicro("BlendMicro");

bm.on('open', function(){
  console.log("open!!");

  // write data
  setInterval(function(){
    bm.write("test");
  }, 500);

  // read data
  bm.on("data", function(data){
    console.log(data.toString());
  });

});
