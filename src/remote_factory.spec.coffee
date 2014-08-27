describe.only 'remote factory', ->

  remoteFactory = require './remote_factory'

  describe '#wiredRemote', ->

    it 'should create a remote which can be populated with manually created domain events', ->

      class ExampleProjection

        initialize: (params) ->
          @$subscribeHandlersWithAggregateId params.aggregateId

        handleExampleCreated: (domainEvent) ->
          @projectedCreated = domainEvent.payload.constructedCreated

        handleExampleModified: (domainEvent) ->
          @projectedModified = domainEvent.payload.constructedModified

      domainEvents =
        ExampleCreated: (params) ->
          @constructedCreated = params.emittedCreated
        ExampleModified: (params) ->
          @constructedModified = params.emittedModified


      wiredRemote = remoteFactory.wiredRemote 'context', domainEvents
      wiredRemote.populateWithDomainEvent 'ExampleCreated', 123, emittedCreated: true
      wiredRemote.populateWithDomainEvent 'ExampleModified', 123, emittedModified: true

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


