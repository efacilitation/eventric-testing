describe 'remote factory', ->

  remoteFactory = require './remote_factory'

  exampleProjection = null
  fakeRemoteContext = null

  domainEvents =
    ExampleCreated: (params) ->
      @assignedCreated = params.emittedCreated
    ExampleModified: (params) ->
      @assignedModified = params.emittedModified


  beforeEach ->
    eventric = require 'eventric'

    exampleProjection =

      initialize: (params, done) ->
        @$subscribeHandlersWithAggregateId params.aggregateId
        done()


      handleExampleCreated: (domainEvent) ->
        @projectedCreated = domainEvent.payload.assignedCreated


      handleExampleModified: (domainEvent) ->
        @projectedModified = domainEvent.payload.assignedModified


    fakeRemoteContext = remoteFactory.setupFakeRemoteContext eventric, 'context', domainEvents


  afterEach ->
    fakeRemoteContext.$destroy()


  describe '#setupFakeRemoteContext', ->

    it 'should throw an error given no eventric instance', ->
      expect(-> remoteFactory.setupFakeRemoteContext null).to.throw Error, /eventric instance missing/


  describe '#fakeRemoteContext.$emitDomainEvent', ->

    describe 'emitting one event', ->

      it 'should publish the domain event to all global subscribers', (done) ->
        fakeRemoteContext.subscribeToAllDomainEvents (domainEvent) ->
          expect(domainEvent.payload.assignedCreated).to.be.ok
          done()
        fakeRemoteContext.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


      it 'should publish the domain event to all subscribers with matching event name', (done) ->
        fakeRemoteContext.subscribeToDomainEvent 'ExampleCreated', (domainEvent) ->
          expect(domainEvent.payload.assignedCreated).to.be.ok
          done()
        fakeRemoteContext.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


      it 'should publish the domain event to all subscribers with matching event name and aggregate id', (done) ->
        fakeRemoteContext.subscribeToDomainEventWithAggregateId 'ExampleCreated', 123, (domainEvent) ->
          expect(domainEvent.payload.assignedCreated).to.be.ok
          done()
        fakeRemoteContext.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true


      it 'should apply the emitted event to projections', ->
        fakeRemoteContext.initializeProjection exampleProjection, aggregateId: 123
        .then ->
          fakeRemoteContext.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
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


        fakeRemoteContext.initializeProjection firstProjection, aggregateId: 123
        fakeRemoteContext.initializeProjection secondProjection, aggregateId: 123


      it 'should emit the domain events to the second projection in the correct order', (done) ->
        fakeRemoteContext.subscribeToDomainEvent 'ExampleModified', ->
          setTimeout ->
            expect(secondProjection.actions[0]).to.equal 'created'
            expect(secondProjection.actions[1]).to.equal 'modified'
            done()
        fakeRemoteContext.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
        fakeRemoteContext.$emitDomainEvent 'ExampleModified', 123, emittedModified: true
        return
        

  describe '#fakeRemoteContext.$onCommand', ->

    it 'should emit the	associated DomainEvent if a specific command is called', (done) ->
      fakeRemoteContext.$onCommand 'myCommand',
        myKey: 'myValue'
      .yieldsDomainEvent 'ExampleCreated', 123,
        emittedCreated: true
      .yieldsDomainEvent 'ExampleModified', 123,
        emittedModified: true

      fakeRemoteContext.subscribeToDomainEventWithAggregateId 'ExampleCreated', 123, (domainEvent) ->
        expect(domainEvent.payload.assignedCreated).to.be.true

      fakeRemoteContext.subscribeToDomainEventWithAggregateId 'ExampleModified', 123, (domainEvent) ->
        expect(domainEvent.payload.assignedModified).to.be.true
        done()

      fakeRemoteContext.command 'myCommand', myKey: 'myValue'
      return


  describe '#fakeRemoteContext.command', ->

    it 'should resolve if there is no command stub registered', ->
      fakeRemoteContext.command 'myCustomCommand'
      .then ->
        expect(true).to.be.ok


    it 'should return a fake promise if a domain event is emitted', ->
      fakeRemoteContext.$onCommand 'myCommand',
        myKey: 'myValue'
      .yieldsDomainEvent 'ExampleCreated', 123,
        emittedCreated: true

      fakeRemoteContext.command 'myCommand',
        myKey: 'myValue'
      .then ->
        expect(true).to.be.ok


  describe '#fakeRemoteContext.query', ->

    it 'should resolve', ->
      fakeRemoteContext.query 'myCustomQuery'
      .then ->
        expect(true).to.be.ok


  describe '#fakeRemoteContext.$waitForEmitDomainEvent', ->

    it 'should wait until the most current emit domain event operation is finished', ->
      domainEventHandlerSpy = sandbox.spy()
      fakeRemoteContext.subscribeToDomainEvent 'ExampleCreated', domainEventHandlerSpy
      fakeRemoteContext.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      fakeRemoteContext.$waitForEmitDomainEvent().then ->
        expect(domainEventHandlerSpy).to.have.been.called


  describe '#fakeRemoteContext.$destroy', ->

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
      fakeRemoteContext.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      fakeRemoteContext.$destroy()
      fakeRemoteContext.initializeProjection exampleReportingProjection, aggregateId: 123
      .then ->
        fakeRemoteContext.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      .then ->
        expect(exampleReportingProjection.exampleCount).to.equal 1


    it 'should unsubscribe all subscribers', (done) ->
      domainEventHandler = sandbox.spy()
      fakeRemoteContext.subscribeToDomainEvent 'ExampleCreated', domainEventHandler
      .then ->
        fakeRemoteContext.subscribeToDomainEvent 'ExampleCreated', domainEventHandler
      .then ->
        fakeRemoteContext.subscribeToDomainEvent 'ExampleCreated', domainEventHandler
      .then ->
        fakeRemoteContext.$destroy()
      .then ->
        fakeRemoteContext.subscribeToDomainEvent 'ExampleCreated', domainEventHandler
        fakeRemoteContext.subscribeToDomainEvent 'ExampleCreated', ->
          expect(domainEventHandler.callCount).to.equal 1
          done()
        fakeRemoteContext.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      return


    it 'should wait until the most current emit domain event operation is finished', ->
      domainEventHandlerSpy = sandbox.spy()
      fakeRemoteContext.subscribeToDomainEvent 'ExampleCreated', domainEventHandlerSpy
      fakeRemoteContext.$emitDomainEvent 'ExampleCreated', 123, emittedCreated: true
      fakeRemoteContext.$destroy().then ->
        expect(domainEventHandlerSpy).to.have.been.called
