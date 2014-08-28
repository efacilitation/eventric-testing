describe 'projection factory', ->

  projectionFactory = require './projection_factory'
  stubFactory = require './stub_factory'

  beforeEach ->
    stubFactory.setStubMethod -> sandbox.stub()
    stubFactory.setConfigureReturnValueMethod (stub, returnValue) -> stub.returns returnValue

  describe '#wiredProjection', ->
    stub = null

    describe 'when given a regular projection', ->

      class ExampleProjection

        handleExampleCreated: (args...) ->
          stub args...


      domainEvents =
        ExampleCreated: (params) ->
          @foo = params.foo


      it 'should instantiate a projection which is capable of emitting and handling domain events', ->
        stub = sandbox.stub()
        projection = projectionFactory.wiredProjection ExampleProjection, domainEvents
        projection.$emitDomainEvent 'ExampleCreated', 1, foo: 'bar'
        expect(stub).to.have.been.calledWith
          context: "eventric-testing"
          name: "ExampleCreated"
          payload:
            foo: 'bar'
          timestamp: sinon.match.number
          id: sinon.match.string
          aggregate: sinon.match.object



    describe 'when given a projection which subscribes to events with a specific aggregate id', ->

      class ExampleProjection

        initialize: (params) ->
          @$subscribeHandlersWithAggregateId params.aggregateId

        handleExampleCreated: (args...) ->
          stub args...


      domainEvents =
        ExampleCreated: (params) ->
          @foo = params.foo


      it 'should instantiate a projection which handles domain events with matching aggregate id', ->
        stub = sandbox.stub()
        projection = projectionFactory.wiredProjection ExampleProjection, aggregateId: 1, domainEvents
        projection.$emitDomainEvent 'ExampleCreated', 1, foo: 'bar'
        expect(stub).to.have.been.called


      it 'should instantiate a projection which does not handle domain events with not matching aggregate id', ->
        stub = sandbox.stub()
        projection = projectionFactory.wiredProjection ExampleProjection, aggregateId: 1, domainEvents
        projection.$emitDomainEvent 'ExampleCreated', 2, foo: 'bar'
        expect(stub).not.to.have.been.called
