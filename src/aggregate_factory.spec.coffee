describe 'aggregate factory', ->

  aggregateFactory = require './aggregate_factory'
  stubFactory = require './stub_factory'


  describe '#fakeAggregate', ->
    class Example
    stub = null

    beforeEach ->
      stub = sandbox.stub()
      stubFactory.setStubMethod -> stub

    it 'should create an instance of the given class', ->
      example = aggregateFactory.fakeAggregate Example
      expect(example).to.be.an.instanceof Example


    it 'should inject an $emitDomainEvent stub', ->
      example = aggregateFactory.fakeAggregate Example
      expect(example.$emitDomainEvent).to.equal stub


  describe '#wiredAggregate', ->
    class Example

      create: (callback) ->
        @$emitDomainEvent 'ExampleCreated', {}
        callback()

      handleExampleCreated: ->
        @created = true


    it 'should create an eventric Aggregate instance which is capable of emitting and handling events', ->
      example = aggregateFactory.wiredAggregate Example, ExampleCreated: ->
      example.create ->
      expect(example.created).to.be.true