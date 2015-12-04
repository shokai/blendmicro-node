var BlendMicro = require("#{__dirname}/../../");
// var BlendMicro = require("blendmicro");

var bm = new BlendMicro(process.argv[2]);

bm.on("open", function(){
  console.log("open");
});

bm.on("data", function(data){
  console.log(data.toString());
});
