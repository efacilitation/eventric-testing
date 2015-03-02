describe 'command/query factory', ->

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

    describe 'given a query callback which rejects', ->

      it 'should reject', ->
        commandQueryFactory.waitUntilQueryIsReady ->
          new Promise (resolve, reject) ->
            reject()
        .catch (error) ->
          expect(error).to.be.ok


    describe 'given a query callback which resolves without a result', ->

      it 'should execute the query callback repeatedly', ->
        callCount = 0
        commandQueryFactory.waitUntilQueryIsReady ->
          callCount++
          new Promise (resolve, reject) ->
            if callCount < 5
              resolve null
            else
              resolve {}
        .then ->
          expect(callCount).to.equal 5


    describe 'given a query callback which resolves with a result', ->

      it 'should resolve with the result', ->
        commandQueryFactory.waitUntilQueryIsReady ->
          new Promise (resolve, reject) ->
            resolve {}
        .then (result) ->
          expect(result).to.be.ok