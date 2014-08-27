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
      $repository:      stubFactory.stub()
      $domainService:   stubFactory.stub()
      $query:           stubFactory.stub()
      $projectionStore: stubFactory.stub()
      $emitDomainEvent: stubFactory.stub()
    stubFactory.configureReturnValue di.$repository, @repositoryStub()
    stubFactory.configureReturnValue di.$projectionStore, projectionFactory.mongoDbStoreStub()
    handler = handler.bind di
    for key of di
      handler[key] = di[key]
    handler


  repositoryStub: ->
    findByIdStub = stubFactory.stub()
    saveStub = stubFactory.stub()
    createStub = stubFactory.stub()
    stubFactory.configureReturnValue findByIdStub, fakePromise.resolve()
    stubFactory.configureReturnValue saveStub, fakePromise.resolve()
    stubFactory.configureReturnValue createStub, fakePromise.resolve()
    return {
      findById: findByIdStub
      create: createStub
      save: saveStub
    }


module.exports = new CommandQueryFactory