eventric  = require 'eventric'
Aggregate = eventric.Aggregate
Context = eventric.Context

stubFactory = require './stub_factory'

class AggregateFactory

  fakeAggregate: (AggregateClass) ->
    aggregate = new AggregateClass
    aggregate.$emitDomainEvent = stubFactory.stub()
    aggregate


  wiredAggregate: (AggregateClass, domainEvents) ->
    aggregate = @instantiateAggregateWithFakeContext AggregateClass, domainEvents
    aggregate.instance


  instantiateAggregateWithFakeContext: (AggregateClass, domainEvents) ->
    fakeContext = @_createFakeContext domainEvents
    new Aggregate fakeContext, eventric, 'Aggregate', AggregateClass


  _createFakeContext: (domainEvents) ->
    contextFake =
      _eventric: eventric
      name: 'eventric-testing'

    name: contextFake.name
    getDomainEvent: (name) -> domainEvents[name]
    createDomainEvent: ->
      Context::createDomainEvent.apply contextFake, arguments


module.exports = new AggregateFactory
