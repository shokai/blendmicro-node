BlendMicro = require "#{__dirname}/../../"
# BlendMicro = require 'blendmicro'

bm = new BlendMicro(process.argv[2])

bm.on 'open', ->
  console.log 'open'

bm.on 'data', (data) ->
  console.log data.toString()
