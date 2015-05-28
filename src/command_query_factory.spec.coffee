describe 'command/query factory', ->

  eventric = require 'eventric'

  commandQueryFactory = require './command_query_factory'
  stubFactory = require './stub_factory'

  beforeEach ->
    stub = sandbox.stub()
    stubFactory.setStubMethod -> stub
    stubFactory.setConfigureReturnValueMethod (stub, returnValue) -> stub.returns returnValue

  describe '#wiredCommandHandler', ->

    it 'should return a command handler with all eventric components injected and exposed', ->
      commandHandler = ->
        expect(@$adapter).to.be.a 'function'
        expect(@$adapter).to.equal wiredCommandHandler.$adapter
        expect(@$aggregate).to.be.an 'object'
        expect(@$aggregate).to.equal wiredCommandHandler.$aggregate
        expect(@$domainService).to.be.a 'function'
        expect(@$domainService).to.equal wiredCommandHandler.$domainService
        expect(@$query).to.be.a 'function'
        expect(@$query).to.equal wiredCommandHandler.$query
        expect(@$projectionStore).to.be.a 'function'
        expect(@$projectionStore).to.equal wiredCommandHandler.$projectionStore
        expect(@$emitDomainEvent).to.be.a 'function'
        expect(@$emitDomainEvent).to.equal wiredCommandHandler.$emitDomainEvent
      wiredCommandHandler = commandQueryFactory.wiredCommandHandler commandHandler
      wiredCommandHandler()


  describe '#wiredQueryHandler', ->

    it 'should return a query handler with all eventric components injected and exposed', ->
      queryHandler = ->
        expect(@$adapter).to.be.a 'function'
        expect(@$adapter).to.equal wiredQueryHandler.$adapter
        expect(@$aggregate).to.be.an 'object'
        expect(@$aggregate).to.equal wiredQueryHandler.$aggregate
        expect(@$domainService).to.be.a 'function'
        expect(@$domainService).to.equal wiredQueryHandler.$domainService
        expect(@$query).to.be.a 'function'
        expect(@$query).to.equal wiredQueryHandler.$query
        expect(@$projectionStore).to.be.a 'function'
        expect(@$projectionStore).to.equal wiredQueryHandler.$projectionStore
        expect(@$emitDomainEvent).to.be.a 'function'
        expect(@$emitDomainEvent).to.equal wiredQueryHandler.$emitDomainEvent
      wiredQueryHandler = commandQueryFactory.wiredCommandHandler queryHandler
      wiredQueryHandler()


  describe '#waitUntilQueryIsReady', ->

    it 'should call the given query on the given context with the given params', ->
      queryStub = sandbox.stub().returns new Promise (resolve) -> resolve {}
      queryParams = {}
      exampleContext = eventric.context 'Example'
      exampleContext.addQueryHandler 'getSomething', queryStub
      exampleContext.initialize()
      .then ->
        commandQueryFactory.waitUntilQueryIsReady exampleContext, 'getSomething', queryParams
      .then ->
        expect(queryStub).to.have.been.calledWith queryParams


    it 'should reject with an error given a query which rejects with an error', ->
      error = new Error
      exampleContext = eventric.context 'Example'
      exampleContext.addQueryHandler 'getSomething', ->
        new Promise (resolve, reject) -> reject error
      exampleContext.initialize()
      .then ->
        commandQueryFactory.waitUntilQueryIsReady exampleContext, 'getSomething'
      .catch (receivedError) ->
        expect(receivedError).to.equal error


    it 'should resolve with the result given a query callback which resolves with a result', ->
      queryResult = {}
      exampleContext = eventric.context 'Example'
      exampleContext.addQueryHandler 'getSomething', ->
        new Promise (resolve) -> resolve queryResult
      exampleContext.initialize()
      .then ->
        commandQueryFactory.waitUntilQueryIsReady exampleContext, 'getSomething'
      .then (receivedResult) ->
        expect(receivedResult).to.equal queryResult


    it 'should execute the query repeatedly given a query which resolves but not with immediately with a result', ->
      exampleContext = eventric.context 'Example'
      callCount = 0
      exampleContext.addQueryHandler 'getSomething', ->
        new Promise (resolve, reject) ->
          callCount++
          if callCount < 5
            resolve null
          else
            resolve {}
      exampleContext.initialize()
      .then ->
        commandQueryFactory.waitUntilQueryIsReady exampleContext, 'getSomething'
      .then ->
        expect(callCount).to.equal 5


    it 'should reject with a descriptive error given a query which does not yield a result within the timeout', ->
      exampleContext = eventric.context 'Example'
      exampleContext.addQueryHandler 'getSomething', ->
        new Promise (resolve) ->
          setTimeout ->
            resolve()
          , 100
      exampleContext.initialize()
      .then ->
        commandQueryFactory.waitUntilQueryIsReady exampleContext, 'getSomething', {foo: 'bar'}, 50
      .catch (error) ->
        expect(error).to.be.an.instanceof Error
        expect(error.message).to.contain 'Example'
        expect(error.message).to.contain 'getSomething'
        expect(error.message).to.match /"foo"\:\s*"bar"/


  describe '#waitUntilCommandResolves', ->

    it 'should call the given command on the given context with the given params', ->
      commandStub = sandbox.stub().returns new Promise (resolve) -> resolve()
      commandParams = {}
      exampleContext = eventric.context 'Example'
      exampleContext.addCommandHandler 'DoSomething', commandStub
      exampleContext.initialize()
      .then ->
        commandQueryFactory.waitUntilCommandResolves exampleContext, 'DoSomething', commandParams
      .then ->
        expect(commandStub).to.have.been.calledWith commandParams


    it 'should resolve with the result given a command which resolves with a result', ->
      commandResult = {}
      exampleContext = eventric.context 'Example'
      exampleContext.addCommandHandler 'DoSomething', ->
        new Promise (resolve) -> resolve commandResult
      exampleContext.initialize()
      .then ->
        commandQueryFactory.waitUntilCommandResolves exampleContext, 'DoSomething'
      .then (receivedResult) ->
        expect(receivedResult).to.equal commandResult


    it 'should execute the command repeatedly given a command which first rejects and resolves after a while', ->
      exampleContext = eventric.context 'Example'
      callCount = 0
      exampleContext.addCommandHandler 'DoSomething', ->
        new Promise (resolve, reject) ->
          callCount++
          if callCount >= 5
            resolve()
          else
            reject()
      exampleContext.initialize()
      .then ->
        commandQueryFactory.waitUntilCommandResolves exampleContext, 'DoSomething'
      .then ->
        expect(callCount).to.equal 5


    it 'should reject with a descriptive error given a command which does not yield a result within the timeout', ->
      exampleContext = eventric.context 'Example'
      exampleContext.addCommandHandler 'DoSomething', ->
        new Promise (resolve) ->
          setTimeout ->
            resolve()
          , 100
      exampleContext.initialize()
      .then ->
        commandQueryFactory.waitUntilCommandResolves exampleContext, 'DoSomething', {foo: 'bar'}, 50
      .catch (error) ->
        expect(error).to.be.an.instanceof Error
        expect(error.message).to.contain 'Example'
        expect(error.message).to.contain 'DoSomething'
        expect(error.message).to.match /"foo"\:\s*"bar"/

