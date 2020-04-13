
const repl = require('repl');
const fs = require('fs')



// Link to Elm code
var Elm = require('./main').Elm;
var main = Elm.Main.init();


// Eval function for the repl
function eval(cmd, _, _,  callback) {
  main.ports.put.subscribe(
    function putCallback (data) {
      main.ports.put.unsubscribe(putCallback)
      callback(null, data)
    }
  )
  main.ports.get.send(cmd)
}


main.ports.sendFileName.subscribe(function(data) {
  var path =  data
  // console.log(path)
  fs.readFile(path, { encoding: 'utf8' }, (err, data) => {
    if (err) {
      console.error(err)
      return
    }
    console.log(data.toString())
    // Crash on next line !!!!
    app.ports.receiveData.send(data.toString());

  })
});


function myWriter(output) {
  return output
}

console.log("\nCommands: (1) show contents (2) load <FILE PATH>\n")

repl.start({ prompt: '> ', eval: eval, writer: myWriter});
