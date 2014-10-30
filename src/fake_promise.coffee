_isPromise = (promise) ->
  promise and typeof promise.then is 'function' and typeof promise.catch is 'function'


class FakePromise

  resolve: (args...) ->
    then: (callback = ->) ->
      promise = callback.apply this, args
      if _isPromise(promise) then promise else @
    catch: ->
      @


  reject: (args...) ->
    then: ->
      @
    catch: (callback = ->) ->
      promise = callback.apply this, args
      if _isPromise(promise) then promise else @
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
