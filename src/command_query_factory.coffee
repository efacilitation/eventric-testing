stubFactory         = require './stub_factory'
fakePromise         = require './fake_promise'
projectionFactory   = require './projection_factory'

class CommandQueryFactory

  wiredCommandHandler: (commandHandler) ->
    @_wireHandler commandHandler


  wiredQueryHandler: (queryHandler) ->
    @_wireHandler queryHandler


  _wireHandler: (handler) ->
    di =
      $adapter:         stubFactory.stub()
      $aggregate:
        create:         stubFactory.stub()
        load:           stubFactory.stub()
      $domainService:   stubFactory.stub()
      $query:           stubFactory.stub()
      $projectionStore: stubFactory.stub()
      $emitDomainEvent: stubFactory.stub()
    stubFactory.configureReturnValue di.$aggregate.create, @aggregateStub()
    stubFactory.configureReturnValue di.$aggregate.load, @aggregateStub()
    stubFactory.configureReturnValue di.$projectionStore, projectionFactory.mongoDbStoreStub()
    handler = handler.bind di
    for key of di
      handler[key] = di[key]
    handler


  aggregateStub: ->
    saveStub = stubFactory.stub()
    stubFactory.configureReturnValue saveStub, fakePromise.resolve()
    return {
      $save: saveStub
    }


  waitForQueryToReturnResult: (context, queryName, params, timeout = 5000) ->
    queryResult = null
    @waitForCondition ->
      context.query queryName, params
      .then (_queryResult) ->
        if _queryResult
          queryResult = _queryResult
          return true
    , timeout
    .then ->
      queryResult
    .catch (error) ->
      if error.message.indexOf('waitForCondition') > -1
        throw new Error """
          waitUntilQueryIsReady timed out for query '#{queryName}' on context '#{context.name}'
          with params #{JSON.stringify(params)}
        """
      else
        throw error


  waitForCommandToResolve: (context, commandName, params, timeout = 5000) ->
    commandResult = null
    @waitForCondition ->
      context.command commandName, params
      .then (_commandResult) ->
        commandResult = _commandResult
        true
      .catch ->
        false
    , timeout
    .then ->
      commandResult
    .catch ->
      throw new Error """
        waitForCommandToResolve timed out for command '#{commandName}' on context '#{context.name}'
        with params #{JSON.stringify(params)}
      """


  waitForCondition: (promiseFactory, timeout = 5000) ->
    new Promise (resolve, reject) ->
      startTime = new Date()

      pollPromise = ->
        promiseFactory()
        .then (isFulfilled) ->

          if isFulfilled
            resolve()
            return

          timeoutExceeded = (new Date() - startTime) >= timeout
          if not timeoutExceeded
            setTimeout pollPromise, 15
            return

          reject new Error """
            waitForCondition timed out for command '#{promiseFactory.toString()}'
          """
        .catch reject

      pollPromise()


module.exports = new CommandQueryFactory
