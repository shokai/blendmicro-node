events = require 'eventemitter2'
noble  = require 'noble'
_      = require 'lodash'
debug  = require('debug')('blendmicro')

module.exports = class BlendMicro extends events.EventEmitter2

  UUIDs =
    service: "713d0000-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')
    tx:      "713d0003-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')
    rx:      "713d0002-503e-4c75-ba94-3148f18d941e".replace(/\-/g, '')

  constructor: (@name = 'BlendMicro') ->

    noble.on 'discover', (peripheral) =>
      if peripheral.advertisement.localName is @name
        debug 'found peripheral'

        peripheral.connect =>

          for signal in ['SIGINT', 'SIGHUP', 'SIGTERM']
            process.on signal, ->
              peripheral.disconnect ->
                process.exit 1

          debug 'connect peripheral'
          @emit 'open'

          peripheral.discoverServices [], (err, services) =>
            service = _.find services, (service) ->
              service.uuid is UUIDs.service
            service.discoverCharacteristics [], (err, chars) =>

              @tx = _.find chars, (char) -> char.uuid is UUIDs.tx
              rx = _.find chars, (char) ->  char.uuid is UUIDs.rx

              rx.on 'read', (data) =>
                @emit 'data', data

              rx.notify true, (err) =>
                if err
                  @emit 'error', err

    @once 'open', ->
      noble.stopScanning()

    noble.startScanning()

    return @

  close: ->

  write: (data) ->
    return unless @tx
    unless data instanceof Buffer
      data = new Buffer data
    @tx.write data
