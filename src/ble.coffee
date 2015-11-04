noble = require 'noble'
debug = require('debug')('blendmicro:ble')


ble =

  noble: noble

  startScanning: ->
    @scanCount += 1
    debug "scan count: #{@scanCount}"
    if @scanCount is 1
      debug "start scanning"
      noble.startScanning()

  stopScanning: ->
    @scanCount -= 1
    debug "scan count: #{@scanCount}"
    if @scanCount is 0
      debug "stop scanning"
      noble.stopScanning()

ble.scanCount = 0

attrs = [
  'state'
]

for attr in attrs
  do (attr) ->
    ble.__defineGetter__ attr, ->
      return noble[attr]

module.exports = ble
