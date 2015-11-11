describe 'aggregate factory', ->

  aggregateFactory = require './aggregate_factory'

  beforeEach ->
    eventric = require 'eventric'
    aggregateFactory.initialize eventric


  describe '#createAggregate', ->

    class ExampleAggregate
      create: (params) ->
        @$emitDomainEvent 'ExampleCreated', {}


      handleExampleCreated: ->
        @created = true


    domainEvents =
      ExampleCreated: ->


    exampleAggregate = null


    beforeEach ->
      sandbox.spy ExampleAggregate::, 'create'
      aggregateFactory.createAggregate ExampleAggregate, domainEvents
      .then (_exampleAggregate) ->
        exampleAggregate = _exampleAggregate


    it 'should create an aggregate instance of the given type', ->
      expect(exampleAggregate).to.be.an.instanceOf ExampleAggregate


    it 'should not call the original create function on the aggregate instance', ->
      expect(ExampleAggregate::create).not.to.have.been.called


    it 'should be possible to call the origial create function on the aggregate', ->
      exampleAggregate.create()
      expect(ExampleAggregate::create).to.have.been.called


    it 'should create an aggregate capable of emitting and handling domain events', ->
      aggregateFactory.createAggregate ExampleAggregate, domainEvents
      .then (exampleAggregate) ->
        exampleAggregate.create()
        expect(exampleAggregate.$emitDomainEvent).to.be.a 'function'
        expect(exampleAggregate.created).to.be.true