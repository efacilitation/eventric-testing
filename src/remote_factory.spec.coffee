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


  afterEach ->
    wiredRemote.$destroy()


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

    describe 'emitting one event', ->

      it 'should publish the domainevent with context', (done) ->
        wiredRemote.subscribeToAllDomainEvents (domainEvent) ->
          expect(domainEvent.payload.assignedCreated).to.be.ok
          done()
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


      it 'should publish the domain event with context, eventName', (done) ->
        wiredRemote.subscribeToDomainEvent 'ExampleCreated', (domainEvent) ->
          expect(domainEvent.payload.assignedCreated).to.be.ok
          done()
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


      it 'should publish the domain event with context, eventName, aggregateId', (done) ->
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


    describe 'given two projections where the first projection handles one event and the other one both events', ->

      projection = null

      beforeEach ->
        class FirstProjection
          initialize: (params, done) ->
            @$subscribeHandlersWithAggregateId params.aggregateId
            done()

          handleExampleCreated: (domainEvent) ->


        class SecondProjection
          initialize: (params, done) ->
            @$subscribeHandlersWithAggregateId params.aggregateId
            @actions = []
            done()

          handleExampleCreated: (domainEvent) ->
            @actions.push 'created'

          handleExampleModified: (domainEvent) ->
            @actions.push 'modified'


        wiredRemote.addProjection 'FirstProjection', FirstProjection
        wiredRemote.addProjection 'SecondProjection', SecondProjection
        wiredRemote.initializeProjectionInstance 'FirstProjection',
          aggregateId: 123
        .then (projectionId) ->
          wiredRemote.initializeProjectionInstance 'SecondProjection',
            aggregateId: 123
        .then (projectionId) ->
          projection = wiredRemote.getProjectionInstance projectionId


      it 'should emit the domain events to the second projection in the correct order', (done) ->
        wiredRemote.subscribeToDomainEvent 'ExampleModified', ->
          setTimeout ->
            expect(projection.actions[0]).to.equal 'created'
            expect(projection.actions[1]).to.equal 'modified'
            done()
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
        wiredRemote.$emitDomainEvent 'ExampleModified', 123, emittedModified: true


  describe '#wiredRemote.$onCommand', ->

    it 'should emit the	associated DomainEvent if a specific command is called', (done) ->
      wiredRemote.$onCommand 'myCommand', myKey: 'myValue'
        .yieldsDomainEvent 'ExampleCreated', 123,
          emittedCreated: true
        .yieldsDomainEvent 'ExampleModified', 123,
          emittedModified: true

      wiredRemote.subscribeToDomainEventWithAggregateId 'ExampleCreated', 123, (domainEvent) ->
        expect(domainEvent.payload.assignedCreated).to.be.true

      wiredRemote.subscribeToDomainEventWithAggregateId 'ExampleModified', 123, (domainEvent) ->
        expect(domainEvent.payload.assignedModified).to.be.true
        done()

      wiredRemote.command 'myCommand', myKey: 'myValue'


  describe '#wiredRemote.command', ->

    it 'should delegate the command function if there is no command stub registered', ->
      wiredRemote.command 'myCustomCommand'
      .catch (error) ->
        expect(error).to.be.defined


    it 'should return a fake promise if a domain event is emitted', ->
      wiredRemote.$onCommand 'myCommand', myKey: 'myValue'
        .yieldsDomainEvent 'ExampleCreated', 123,
          emittedCreated: true
      wiredRemote.command 'myCommand', myKey: 'myValue'
      .then ->
        expect(true).to.be.ok


  describe.only '#wiredRemote.$waitForEmitDomainEvent', ->

    it 'should wait until the most current emit domain event operation is finished', ->
      domainEventHandlerSpy = sandbox.spy()
      wiredRemote.subscribeToDomainEvent 'ExampleCreated', domainEventHandlerSpy
      wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      wiredRemote.$waitForEmitDomainEvent().then ->
        expect(domainEventHandlerSpy).to.have.been.called



  describe '#wiredRemote.$destroy', ->

    class ExampleReportingProjection
      initialize: (params, done) ->
        @exampleCount = 0
        @$subscribeHandlersWithAggregateId params.aggregateId
        done()

      handleExampleCreated: () ->
        @exampleCount++


    it 'should remove the stored domain events', (done) ->
      wiredRemote.$populateWithDomainEvent 'ExampleCreated', 123, emittedCreated: true
      wiredRemote.$destroy()
      wiredRemote.addProjection 'ExampleReportingProjection', ExampleReportingProjection
      wiredRemote.initializeProjectionInstance 'ExampleReportingProjection',
        aggregateId: 123
      .then (projectionId) ->
        projection = wiredRemote.getProjectionInstance projectionId
        wiredRemote.subscribe 'projection:ExampleReportingProjection:changed', ->
          expect(projection.exampleCount).to.equal 1
          done()
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


    it 'should unsubscribe all subscribers', (done) ->
      domainEventHandler = sandbox.spy()
      wiredRemote.subscribeToDomainEvent 'ExampleCreated', domainEventHandler
      .then ->
        wiredRemote.subscribeToDomainEvent 'ExampleCreated', domainEventHandler
      .then ->
        wiredRemote.subscribeToDomainEvent 'ExampleCreated', domainEventHandler
      .then ->
        wiredRemote.$destroy()
      .then ->
        wiredRemote.subscribeToDomainEvent 'ExampleCreated', domainEventHandler
        wiredRemote.subscribeToDomainEvent 'ExampleCreated', ->
          expect(domainEventHandler.callCount).to.equal 1
          done()
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


    it 'should wait until the most current emit domain event operation is finished', ->
      domainEventHandlerSpy = sandbox.spy()
      wiredRemote.subscribeToDomainEvent 'ExampleCreated', domainEventHandlerSpy
      wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      wiredRemote.$destroy().then ->
        expect(domainEventHandlerSpy).to.have.been.called

