describe 'domain event handlers factory', ->

  domainEventHandlersFactory = require './domain_event_handlers_factory'
  stubFactory = require './stub_factory'

  beforeEach ->
    stubFactory.setStubMethod -> sandbox.stub()
    stubFactory.setConfigureReturnValueMethod (stub, returnValue) -> stub.returns returnValue

  describe '#wiredDomainEventHandlers', ->
    stub = null

    domainEventHandlers =
      ExampleCreated: (args...) ->
        stub args...


    domainEvents =
      ExampleCreated: (params) ->
        @foo = params.foo


    it 'should instantiate a projection which is capable of emitting and handling domain events', ->
      stub = sandbox.stub()
      wiredHandlers = domainEventHandlersFactory.wiredDomainEventHandlers domainEventHandlers, domainEvents
      wiredHandlers.$emitDomainEvent 'ExampleCreated', 1, foo: 'bar'
      expect(stub).to.have.been.calledWith
        context: "eventric-testing"
        name: "ExampleCreated"
        payload:
          foo: 'bar'
        timestamp: sinon.match.number
        id: sinon.match.string
        aggregate: sinon.match.object