var exec = require('cordova/exec');

var escpos = {
  connect: function(opts, success, error) {
    // opts: {type:'tcp'|'ble'|'externalAccessory', host, port, peripheralId}
    exec(success, error, 'ESCPosPrinter', 'connect', [opts]);
  },
  writeBase64: function(b64, success, error) {
    // kirim raw data sebagai base64
    exec(success, error, 'ESCPosPrinter', 'writeBase64', [b64]);
  },
  writeHex: function(hexString, success, error) {
    exec(success, error, 'ESCPosPrinter', 'writeHex', [hexString]);
  },
  disconnect: function(success, error) {
    exec(success, error, 'ESCPosPrinter', 'disconnect', []);
  }
};

module.exports = escpos;
