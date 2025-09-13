var exec = require('cordova/exec');

var escpos = {
  connect: function(opts, success, error) {
    exec(success, error, 'ESCPosPrinter', 'connect', [opts]);
  },
  writeBase64: function(b64, success, error) {
    exec(success, error, 'ESCPosPrinter', 'writeBase64', [b64]);
  },
  writeHex: function(hexString, success, error) {
    exec(success, error, 'ESCPosPrinter', 'writeHex', [hexString]);
  },
  disconnect: function(success, error) {
    exec(success, error, 'ESCPosPrinter', 'disconnect', []);
  },
  onConnect: function(cb) {
    escpos._onConnect = cb;
  },
  onDisconnect: function(cb) {
    escpos._onDisconnect = cb;
  },
  onError: function(cb) {
    escpos._onError = cb;
  },
  _dispatchEvent: function(type, msg) {
    if (type === 'connect' && typeof escpos._onConnect === 'function') escpos._onConnect(msg);
    if (type === 'disconnect' && typeof escpos._onDisconnect === 'function') escpos._onDisconnect(msg);
    if (type === 'error' && typeof escpos._onError === 'function') escpos._onError(msg);
  }
};

// terima callback event dari native
exec(function (event) {
  if (event && event.type) {
    escpos._dispatchEvent(event.type, event.msg);
  }
}, null, 'ESCPosPrinter', 'registerListener', []);

module.exports = escpos;
