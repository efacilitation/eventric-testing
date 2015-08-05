describe 'aggregate factory', ->

  aggregateFactory = require './aggregate_factory'

  describe '#createAggregate', ->

    class ExampleAggregate
      create: (params) ->
        @$emitDomainEvent 'ExampleCreated', {}


      handleExampleCreated: ->
        @created = true


    domainEvents =
      ExampleCreated: ->


    it 'should create an aggregate instance of the given type', ->
      aggregateFactory.createAggregate
        aggregateClass: ExampleAggregate
        domainEvents: domainEvents
      .then (exampleAggregate) ->
        expect(exampleAggregate).to.be.an.instanceOf ExampleAggregate


    it 'should call the create function with the passed in createParams', ->
      createParams = {}
      sandbox.spy ExampleAggregate::, 'create'
      aggregateFactory.createAggregate
        aggregateClass: ExampleAggregate
        domainEvents: domainEvents
        createParams: createParams
      .then (exampleAggregate) ->
        expect(ExampleAggregate::create).to.have.been.calledWith createParams


    it 'should create an aggregate capable of emitting and handling domain events', ->
      aggregateFactory.createAggregate
        aggregateClass: ExampleAggregate
        domainEvents: domainEvents
      .then (exampleAggregate) ->
        expect(exampleAggregate.$emitDomainEvent).to.be.a 'function'
        expect(exampleAggregate.created).to.be.true