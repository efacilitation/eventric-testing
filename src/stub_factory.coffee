class StubFactory

  constructor: ->
    @stub = -> ->
    @configureReturnValue = ->
      throw new Error 'configureReturnValue not configured'


  setStubMethod: (@stub) ->


  setConfigureReturnValueMethod: (@configureReturnValue) ->


module.exports = new StubFactory