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


  waitUntilQueryIsReady: (context, queryName, params, timeout = 5000) ->
    new Promise (resolve, reject) ->
      startTime = new Date()

      pollQuery = ->
        context.query queryName, params
        .then (result) ->
          if result
            resolve result
          else if (new Date() - startTime) >= timeout
            reject new Error """
              waitUntilQueryIsReady timed out for query '#{queryName}' on context '#{context.name}'
              with params #{JSON.stringify(params)}
            """
          else
            setTimeout pollQuery, 15
        .catch (error) ->
          reject error || new Error 'waitUntilQueryIsReady error'

      pollQuery()


module.exports = new CommandQueryFactory