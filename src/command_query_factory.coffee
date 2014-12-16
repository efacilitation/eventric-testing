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
      $aggregate:       stubFactory.stub()
      $domainService:   stubFactory.stub()
      $query:           stubFactory.stub()
      $projectionStore: stubFactory.stub()
      $emitDomainEvent: stubFactory.stub()
    stubFactory.configureReturnValue di.$aggregate, @aggregateStub()
    stubFactory.configureReturnValue di.$projectionStore, projectionFactory.mongoDbStoreStub()
    handler = handler.bind di
    for key of di
      handler[key] = di[key]
    handler


  aggregateStub: ->
    loadStub = stubFactory.stub()
    createStub = stubFactory.stub()
    stubFactory.configureReturnValue loadStub, fakePromise.resolve()
    stubFactory.configureReturnValue createStub, fakePromise.resolve()
    return {
      load: loadStub
      create: createStub
    }


module.exports = new CommandQueryFactory