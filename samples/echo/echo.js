var BlendMicro = require(__dirname+'/../../');
// var BlendMicro = require('blendmicro');

var bm = new BlendMicro("BlendMicro");

bm.on('open', function(){
  console.log("open!!");

  // read data
  bm.on("data", function(data){
    console.log(data.toString());
    bm.updateRssi(function(err, rssi){
      console.log("rssi:"+rssi);
    });
  });

});

bm.on('close', function(){
  console.log('close!!');
});

process.stdin.setEncoding("utf8");

// write data from STDIN
process.stdin.on("readable", function(){
  var chunk = process.stdin.read();
  if(chunk == null) return;
  chunk = chunk.toString().replace(/[\r\n]/g, '');
  bm.write(chunk);
});
