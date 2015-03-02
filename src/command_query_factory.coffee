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


  waitUntilQueryIsReady: (queryCallback) ->
    new Promise (resolve, reject) ->
      pollQuery = ->
        queryCallback()
        .then (result) ->
          if result
            resolve result
          else
            setTimeout pollQuery, 0
        .catch (error) ->
          reject error || new Error 'waitUntilQueryIsReady error'
      pollQuery()


module.exports = new CommandQueryFactory