class FakePromise

  resolve: (args...) ->
    then: (callback = ->) ->
      callback.apply this, args
      @
    catch: ->
      @


  reject: (args...) ->
    then: ->
      @
    catch: (callback = ->) ->
      callback.apply this, args
      @


  resolveAsync: (args...) ->
    then: (callback = ->) ->
      setTimeout ->
        callback.apply this, args
      , 0
      @
    catch: ->
      @


  rejectAsync: (args...) ->
    then: ->
      @
    catch: (callback = ->) ->
      setTimeout ->
        callback.apply this, args
      , 0
      @


module.exports = new FakePromise