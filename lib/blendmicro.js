(function() {
  var BlendMicro, _, debug, events, noble,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  events = require('eventemitter2');

  noble = require('noble');

  _ = require('lodash');

  debug = require('debug')('blendmicro');

  module.exports = BlendMicro = (function(superClass) {
    var UUID_LIST;

    extend(BlendMicro, superClass);

    UUID_LIST = {
      service: "713d0000-503e-4c75-ba94-3148f18d941e".replace(/\-/g, ''),
      tx: "713d0003-503e-4c75-ba94-3148f18d941e".replace(/\-/g, ''),
      rx: "713d0002-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')
    };

    function BlendMicro(name) {
      this.name = name != null ? name : 'BlendMicro';
      this.__defineGetter__('state', (function(_this) {
        return function() {
          var ref;
          return ((ref = _this.peripheral) != null ? ref.state : void 0) || 'discover';
        };
      })(this));
      noble.on('stateChange', function(state) {
        if (state === 'poweredOn') {
          return noble.startScanning();
        } else {
          return noble.stopScanning();
        }
      });
      noble.on('discover', (function(_this) {
        return function(peripheral) {
          if (peripheral.advertisement.localName !== _this.name) {
            return;
          }
          _this.peripheral = peripheral;
          debug('found peripheral');
          _this.peripheral.connect(function() {
            var i, len, ref, signal;
            ref = ['SIGINT', 'SIGHUP', 'SIGTERM'];
            for (i = 0, len = ref.length; i < len; i++) {
              signal = ref[i];
              process.on(signal, function() {
                if (_this.peripheral.state === 'disconnected') {
                  process.exit(1);
                  return;
                }
                _this.peripheral.disconnect(function() {
                  return process.exit(1);
                });
                return setTimeout(function() {
                  debug('peripheral.disconnect timeout (2000 msec)');
                  return process.exit(1);
                }, 2000);
              });
            }
            debug('connect peripheral');
            _this.emit('open');
            return _this.peripheral.discoverServices([], function(err, services) {
              var service;
              service = _.find(services, function(service) {
                return service.uuid === UUID_LIST.service;
              });
              return service.discoverCharacteristics([], function(err, chars) {
                var rx;
                _this.tx = _.find(chars, function(char) {
                  return char.uuid === UUID_LIST.tx;
                });
                if (!_this.tx) {
                  debug('ERROR: TX characteristics not found');
                }
                rx = _.find(chars, function(char) {
                  return char.uuid === UUID_LIST.rx;
                });
                if (!rx) {
                  return debug('ERROR: RX characteristics not found');
                } else {
                  rx.on('read', function(data) {
                    return _this.emit('data', data);
                  });
                  return rx.notify(true, function(err) {
                    if (err) {
                      return debug(err);
                    }
                  });
                }
              });
            });
          });
          return _this.peripheral.on('disconnect', function() {
            return _this.emit('close');
          });
        };
      })(this));
      this.once('open', function() {
        return noble.stopScanning();
      });
    }

    BlendMicro.prototype.close = function(callback) {
      return this.peripheral.disconnect(callback);
    };

    BlendMicro.prototype.write = function(data) {
      if (!this.tx) {
        return;
      }
      if (!(data instanceof Buffer)) {
        data = new Buffer(data);
      }
      return this.tx.write(data);
    };

    BlendMicro.prototype.updateRssi = function(callback) {
      var ref;
      return (ref = this.peripheral) != null ? ref.updateRssi(callback) : void 0;
    };

    return BlendMicro;

  })(events.EventEmitter2);

}).call(this);
