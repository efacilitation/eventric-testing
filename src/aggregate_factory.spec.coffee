describe 'aggregate factory', ->

  aggregateFactory = require './aggregate_factory'

  describe '#createAggregate', ->
    class Example

      create: ->
        @$emitDomainEvent 'ExampleCreated', {}


      handleExampleCreated: ->
        @created = true


    it 'should create an aggregate instance which is capable of emitting and handling events', ->
      domainEvents =
        ExampleCreated: ->
      aggregateFactory.createAggregate Example, domainEvents
      .then (example) ->
        expect(example.created).to.be.true