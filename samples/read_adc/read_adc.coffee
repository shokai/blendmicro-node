BlendMicro = require "#{__dirname}/../../"
# BlendMicro = require 'blendmicro'

bm = new BlendMicro()

bm.on 'open', ->
  console.log 'open'

bm.on 'data', (data) ->
  console.log data.toString()
