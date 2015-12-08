events = require 'eventemitter2'
ble    = require './ble'
_      = require 'lodash'
debug  = require('debug')('blendmicro')

UUID_LIST =
  blendmicro:
    service: "713d0000-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')
    tx:      "713d0003-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')
    rx:      "713d0002-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')
  mbed_uart:
    service: "6e400001-b5a3-f393-e0a9-e50e24dcca9e".replace(/\-/g, '')
    tx:      "6e400002-b5a3-f393-e0a9-e50e24dcca9e".replace(/\-/g, '')
    rx:      "6e400003-b5a3-f393-e0a9-e50e24dcca9e".replace(/\-/g, '')

module.exports = class BlendMicro extends events.EventEmitter2

  constructor: (@name = 'BlendMicro') ->
    @peripheral = null
    @reconnect = true
    @write_queue = []
    @writeInterval = 100  # msec
    @writePacketSize = 20 # bytes

    @__defineGetter__ 'state', =>
      @peripheral?.state or 'discover'

    @open @name

  open: (@name) ->
    return if @peripheral isnt null
    debug "search \"#{@name}\""

    if ble.state is 'poweredOn'
      ble.startScanning()

    ble.noble.on 'stateChange', (state) ->
      if state is 'poweredOn'
        ble.startScanning()
      else
        ble.stopScanning()

    ble.noble.on 'discover', (peripheral) =>
      debug "discover \"#{peripheral.advertisement.localName}\""
      return if @peripheral isnt null
      return if peripheral.advertisement.localName isnt @name
      @peripheral = peripheral
      debug "found peripheral \"#{@name}\""

      @peripheral.connect =>

        ## trap SIGNALs
        for signal in ['SIGINT', 'SIGHUP', 'SIGTERM']
          process.on signal, =>
            unless @peripheral?
              process.exit 1
              return
            if @peripheral.state is 'disconnected'
              process.exit 1
              return
            @peripheral?.disconnect ->
              process.exit 1
            setTimeout ->
              debug 'peripheral.disconnect timeout (2000 msec)'
              process.exit 1
            , 2000

        debug 'connect peripheral'
        @emit 'open'

        ## find RX/TX characteristics
        @peripheral.discoverServices [], (err, services) =>
          device_type = null
          service = _.find services, (service) ->
            for type, uuids of UUID_LIST
              if service.uuid is uuids.service
                device_type = type
                return true
          return unless service
          service.discoverCharacteristics [], (err, chars) =>
            @tx = _.find chars, (char) -> char.uuid is UUID_LIST[device_type].tx
            unless @tx
              debug 'ERROR: TX characteristics not found'
            rx = _.find chars, (char) ->  char.uuid is UUID_LIST[device_type].rx
            unless rx
              debug 'ERROR: RX characteristics not found'
            else
              rx.on 'read', (data) =>
                @emit 'data', data
              rx.notify true, (err) =>
                debug err if err

      @peripheral.on 'disconnect', =>
        debug 'disconnect'
        @peripheral.removeAllListeners()
        @peripheral = null
        if @reconnect
          debug 're-start scanning'
          ble.startScanning()
        @emit 'close'

    @on 'open', ->
      ble.stopScanning()

  close: (callback) ->
    ble.noble.removeAllListeners()
    @peripheral.removeAllListeners()
    @peripheral.disconnect =>
      callback?()
      @emit 'close'
    @peripheral = null

  write: (data, callback) ->
    unless @peripheral and @tx
      return callback? 'disconnected'
    unless data instanceof Buffer
      data = new Buffer data

    ## queue
    packet_num = Math.floor((data.length-1)/@writePacketSize) + 1
    debug "write #{data.length}bytes #{packet_num}packets"
    for i in [0...packet_num]
      start_at = i*@writePacketSize
      @write_queue.push data.slice start_at, start_at+@writePacketSize

    return if @write_interval_id
    @write_interval_id = setInterval =>
      if @write_queue.length > 0 and @peripheral
        @tx.write @write_queue.shift()
      else
        clearInterval @write_interval_id
        @write_interval_id = null
        @write_queue = []
    , @writeInterval

  updateRssi: (callback) ->
    @peripheral?.updateRssi callback
