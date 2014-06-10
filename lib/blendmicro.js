(function() {
  var BlendMicro, events,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  events = require('eventemitter2');

  module.exports = BlendMicro = (function(_super) {
    __extends(BlendMicro, _super);

    function BlendMicro() {
      return BlendMicro.__super__.constructor.apply(this, arguments);
    }

    return BlendMicro;

  })(events.EventEmitter2);

}).call(this);
