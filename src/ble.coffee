noble = require 'noble'
debug = require('debug')('blendmicro:ble')
{EventEmitter2} = require 'eventemitter2'

module.exports = class BLE extends EventEmitter2

  constructor: ->
    debug 'start ble class'
    @noble = noble
    @scanCount = 0
    attrs = [ 'state' ]

    for attr in attrs
      do (attr) =>
        @__defineGetter__ attr, ->
          return noble[attr]

  startScanning: ->
    @scanCount += 1
    debug "scan count: #{@scanCount}"
    if @scanCount is 1
      debug "start scanning"
      noble.startScanning [], true

  stopScanning: ->
    @scanCount -= 1
    debug "scan count: #{@scanCount}"
    if @scanCount is 0
      debug "stop scanning"
      noble.stopScanning()
