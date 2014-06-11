events = require 'eventemitter2'
noble  = require 'noble'
_      = require 'lodash'
debug  = require('debug')('blendmicro')

module.exports = class BlendMicro extends events.EventEmitter2

  UUID_LIST =
    service: "713d0000-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')
    tx:      "713d0003-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')
    rx:      "713d0002-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')

  constructor: (@name = 'BlendMicro') ->

    @__defineGetter__ 'state', =>
      @peripheral?.state or 'discover'

    noble.on 'discover', (peripheral) =>
      if peripheral.advertisement.localName isnt @name
        return
      @peripheral = peripheral
      debug 'found peripheral'

      @peripheral.connect =>

        ## trap SIGNALs
        for signal in ['SIGINT', 'SIGHUP', 'SIGTERM']
          process.on signal, =>
            if @peripheral.state is 'disconnected'
              process.exit 1
              return
            @peripheral.disconnect ->
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
        @emit 'close'

    @once 'open', ->
      noble.stopScanning()

    noble.startScanning()

    return @

  close: (callback) ->
    @peripheral.disconnect callback

  write: (data) ->
    return unless @tx
    unless data instanceof Buffer
      data = new Buffer data
    @tx.write data
