## BLE Manager

noble = require 'noble'
debug = require('debug')('blendmicro:ble')
{EventEmitter2} = require 'eventemitter2'

STATE = require './state'

module.exports = class BLE extends EventEmitter2

  constructor: ->
    @devices = []
    @scanCount = 0
    attrs = [ 'state' ]

    for attr in attrs
      do (attr) =>
        @__defineGetter__ attr, ->
          return noble[attr]

    noble.on 'discover', (peripheral) =>
      for device in @devices
        if device.state is STATE.SCAN and
           device.name is peripheral.advertisement.localName
          device.emit 'discover', peripheral


  open: (device) ->
    return if @devices.indexOf(device) > -1
    @devices.push device

  close: (device) ->
    @devices.splice @devices.indexOf(device), 1

  getNumberOfScanningDevices: ->
    @devices
      .filter (device) -> device.state is STATE.SCAN
      .length

  startScanning: ->
    scanCount = @getNumberOfScanningDevices()
    debug "scanCount: #{scanCount}"
    return if scanCount isnt 1
    debug "noble.startScanning"
    if noble.state is 'poweredOn'
      return noble.startScanning [], true
    noble.once 'stateChange', (state) ->
      if state is 'poweredOn'
        noble.startScanning [], true
      else
        noble.stopScanning()

  stopScanning: ->
    scanCount = @getNumberOfScanningDevices()
    debug "scanCount: #{scanCount}"
    return if scanCount isnt 0
    debug "noble.stopScanning"
    noble.stopScanning()
