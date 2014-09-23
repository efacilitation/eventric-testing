describe 'remote factory', ->

  remoteFactory = require './remote_factory'

  class ExampleProjection
    initialize: (params, done) ->
      @$subscribeHandlersWithAggregateId params.aggregateId
      done()


    handleExampleCreated: (domainEvent) ->
      @projectedCreated = domainEvent.payload.assignedCreated


    handleExampleModified: (domainEvent) ->
      @projectedModified = domainEvent.payload.assignedModified


  domainEvents =
    ExampleCreated: (params) ->
      @assignedCreated = params.emittedCreated
    ExampleModified: (params) ->
      @assignedModified = params.emittedModified


  wiredRemote = null
  beforeEach ->
    wiredRemote = remoteFactory.wiredRemote 'context', domainEvents

  describe '#wiredRemote', ->

    it 'should create a wired remote with helper functions', ->
      expect(wiredRemote.$populateWithDomainEvent).to.be.a 'function'
      expect(wiredRemote.$emitDomainEvent).to.be.a 'function'


  describe '#wiredRemote.$populateWithDomainEvent', ->

    it 'should populate the remote with the given event which is applied to later created projections', ->
      wiredRemote.$populateWithDomainEvent 'ExampleCreated', 123, emittedCreated: true
      wiredRemote.$populateWithDomainEvent 'ExampleModified', 123, emittedModified: true
      wiredRemote.addProjection 'ExampleProjection', ExampleProjection
      wiredRemote.initializeProjectionInstance 'ExampleProjection',
        aggregateId: 123
      .then (projectionId) ->
        projection = wiredRemote.getProjectionInstance projectionId
        expect(projection.projectedCreated).to.be.true
        expect(projection.projectedModified).to.be.true


    it 'should throw an error if the event to populate with is not registered', ->
      wiredRemote = remoteFactory.wiredRemote 'context', {}
      expect(-> wiredRemote.populateWithDomainEvent 'Foobar').to.throw Error


  describe '#wiredRemote.$emitDomainEvent', ->

    it 'should publish the DomainEvent with context', (done) ->
      wiredRemote.subscribeToAllDomainEvents (domainEvent) ->
        expect(domainEvent.payload.assignedCreated).to.be.ok
        done()
      wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


    it 'should publish the DomainEvent with context, eventName', (done) ->
      wiredRemote.subscribeToDomainEvent 'ExampleCreated', (domainEvent) ->
        expect(domainEvent.payload.assignedCreated).to.be.ok
        done()
      wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


    it 'should publish the DomainEvent with context, eventName, aggregateId', (done) ->
      wiredRemote.subscribeToDomainEventWithAggregateId 'ExampleCreated', 123, (domainEvent) ->
        expect(domainEvent.payload.assignedCreated).to.be.ok
        done()
      wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


    it 'should populate the remote with the given event which is applied to later created projections', ->
      wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      wiredRemote.addProjection 'ExampleProjection', ExampleProjection
      wiredRemote.initializeProjectionInstance 'ExampleProjection',
        aggregateId: 123
      .then (projectionId) ->
        projection = wiredRemote.getProjectionInstance projectionId
        expect(projection.projectedCreated).to.be.true


    it 'should publish the domain event so domain event subscribers are notified of it', (done) ->
      wiredRemote.addProjection 'ExampleProjection', ExampleProjection
      wiredRemote.initializeProjectionInstance 'ExampleProjection',
        aggregateId: 123
      .then (projectionId) ->
        wiredRemote.subscribe 'projection:ExampleProjection:changed', (event) ->
          expect(event.projection.projectedCreated).to.be.true
          done()
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true