events = require 'eventemitter2'
ble    = require './ble'
_      = require 'lodash'
debug  = require('debug')('blendmicro')

UUID_LIST =
  service: "713d0000-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')
  tx:      "713d0003-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')
  rx:      "713d0002-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')

module.exports = class BlendMicro extends events.EventEmitter2

  constructor: (@name = 'BlendMicro') ->
    @peripheral = null
    @reconnect = true

    @__defineGetter__ 'state', =>
      @peripheral?.state or 'discover'

    @open @name

  open: (@name) ->
    return if @peripheral isnt null

    if ble.state is 'poweredOn'
      ble.startScanning()

    ble.noble.on 'stateChange', (state) ->
      if state is 'poweredOn'
        ble.startScanning()
      else
        ble.stopScanning()

    ble.noble.on 'discover', (peripheral) =>
      return if @peripheral isnt null
      return if peripheral.advertisement.localName isnt @name
      @peripheral = peripheral
      debug 'found peripheral'

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
          service = _.find services, (service) ->
            service.uuid is UUID_LIST.service
          service.discoverCharacteristics [], (err, chars) =>
            @tx = _.find chars, (char) -> char.uuid is UUID_LIST.tx
            unless @tx
              debug 'ERROR: TX characteristics not found'
            rx = _.find chars, (char) ->  char.uuid is UUID_LIST.rx
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

  write: (data) ->
    return unless @tx
    unless data instanceof Buffer
      data = new Buffer data
    @tx.write data

  updateRssi: (callback) ->
    @peripheral?.updateRssi callback
