class EventualConsistencyUtilities

  waitForQueryToReturnResult: (context, queryName, params, timeout = 5000) ->
    @waitForResult ->
      context.query queryName, params
    , timeout
    .catch (error) ->
      if error?.message?.indexOf('waitForResult') > -1
        throw new Error """
          waitForQueryToReturnResult timed out for query '#{queryName}' on context '#{context.name}'
          with params #{JSON.stringify(params)}
        """
      else
        throw error


  waitForCommandToResolve: (context, commandName, params, timeout = 5000) ->
    @waitForResult ->
      context.command commandName, params
      .then (result) ->
        return result || true
      .catch ->
        return undefined
    , timeout
    .catch ->
      throw new Error """
        waitForCommandToResolve timed out for command '#{commandName}' on context '#{context.name}'
        with params #{JSON.stringify(params)}
      """


  waitForResult: (promiseFactory, timeout = 5000) ->
    new Promise (resolve, reject) ->
      startTime = new Date()

      pollPromise = ->
        promiseFactory()
        .then (result) ->
          if result?
            resolve result
            return

          timeoutExceeded = (new Date() - startTime) >= timeout
          if not timeoutExceeded
            setTimeout pollPromise, 15
            return

          reject new Error """
            waitForResult timed out for '#{promiseFactory.toString()}'
          """
        .catch reject

      pollPromise()


module.exports = new EventualConsistencyUtilities
