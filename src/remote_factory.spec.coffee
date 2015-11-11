describe 'remote factory', ->

  remoteFactory = require './remote_factory'

  exampleProjection = null
  wiredRemote = null

  domainEvents =
    ExampleCreated: (params) ->
      @assignedCreated = params.emittedCreated
    ExampleModified: (params) ->
      @assignedModified = params.emittedModified


  beforeEach ->
    eventric = require 'eventric'
    remoteFactory.initialize eventric

    exampleProjection =

      initialize: (params, done) ->
        @$subscribeHandlersWithAggregateId params.aggregateId
        done()


      handleExampleCreated: (domainEvent) ->
        @projectedCreated = domainEvent.payload.assignedCreated


      handleExampleModified: (domainEvent) ->
        @projectedModified = domainEvent.payload.assignedModified


    wiredRemote = remoteFactory.wiredRemote 'context', domainEvents


  afterEach ->
    wiredRemote.$destroy()

  describe '#wiredRemote.$emitDomainEvent', ->

    describe 'emitting one event', ->

      it 'should publish the domain event to all global subscribers', (done) ->
        wiredRemote.subscribeToAllDomainEvents (domainEvent) ->
          expect(domainEvent.payload.assignedCreated).to.be.ok
          done()
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


      it 'should publish the domain event to all subscribers with matching event name', (done) ->
        wiredRemote.subscribeToDomainEvent 'ExampleCreated', (domainEvent) ->
          expect(domainEvent.payload.assignedCreated).to.be.ok
          done()
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


      it 'should publish the domain event to all subscribers with matching event name and aggregate id', (done) ->
        wiredRemote.subscribeToDomainEventWithAggregateId 'ExampleCreated', 123, (domainEvent) ->
          expect(domainEvent.payload.assignedCreated).to.be.ok
          done()
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


      it 'should apply the emitted event to projections', ->
        wiredRemote.initializeProjection exampleProjection, aggregateId: 123
        .then ->
          wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
        .then ->
          expect(exampleProjection.projectedCreated).to.be.true


    describe 'given two projections where the first projection handles one event and the other one both events', ->

      firstProjection = null
      secondProjection = null

      beforeEach ->
        firstProjection =
          initialize: (params, done) ->
            @$subscribeHandlersWithAggregateId params.aggregateId
            done()

          handleExampleCreated: (domainEvent) ->


        secondProjection =
          initialize: (params, done) ->
            @$subscribeHandlersWithAggregateId params.aggregateId
            @actions = []
            done()

          handleExampleCreated: (domainEvent) ->
            @actions.push 'created'

          handleExampleModified: (domainEvent) ->
            @actions.push 'modified'


        wiredRemote.initializeProjection firstProjection, aggregateId: 123
        wiredRemote.initializeProjection secondProjection, aggregateId: 123


      it 'should emit the domain events to the second projection in the correct order', (done) ->
        wiredRemote.subscribeToDomainEvent 'ExampleModified', ->
          setTimeout ->
            expect(secondProjection.actions[0]).to.equal 'created'
            expect(secondProjection.actions[1]).to.equal 'modified'
            done()
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
        wiredRemote.$emitDomainEvent 'ExampleModified', 123, emittedModified: true


  describe '#wiredRemote.$onCommand', ->

    it 'should emit the	associated DomainEvent if a specific command is called', (done) ->
      wiredRemote.$onCommand 'myCommand',
        myKey: 'myValue'
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
      wiredRemote.$onCommand 'myCommand',
        myKey: 'myValue'
      .yieldsDomainEvent 'ExampleCreated', 123,
        emittedCreated: true

      wiredRemote.command 'myCommand',
        myKey: 'myValue'
      .then ->
        expect(true).to.be.ok


  describe '#wiredRemote.$waitForEmitDomainEvent', ->

    it 'should wait until the most current emit domain event operation is finished', ->
      domainEventHandlerSpy = sandbox.spy()
      wiredRemote.subscribeToDomainEvent 'ExampleCreated', domainEventHandlerSpy
      wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      wiredRemote.$waitForEmitDomainEvent().then ->
        expect(domainEventHandlerSpy).to.have.been.called


  describe '#wiredRemote.$destroy', ->

    exampleReportingProjection = null

    beforeEach ->
      exampleReportingProjection =
        initialize: (params, done) ->
          @exampleCount = 0
          @$subscribeHandlersWithAggregateId params.aggregateId
          done()

        handleExampleCreated: ->
          @exampleCount++


    it 'should remove the stored domain events', ->
      projection = null
      wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      wiredRemote.$destroy()
      wiredRemote.initializeProjection exampleReportingProjection, aggregateId: 123
      .then ->
        wiredRemote.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      .then ->
        expect(exampleReportingProjection.exampleCount).to.equal 1


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
