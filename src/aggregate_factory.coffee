Aggregate = require 'eventric/src/aggregate'

stubFactory = require './stub_factory'

class AggregateFactory

  fakeAggregate: (AggregateClass) ->
    aggregate = new AggregateClass
    aggregate.$emitDomainEvent = stubFactory.stub()
    aggregate


  wiredAggregate: (AggregateClass, domainEvents) ->
    aggregate = @instantiateAggregateWithFakeContext AggregateClass, domainEvents
    aggregate.root


  instantiateAggregateWithFakeContext: (AggregateClass, domainEvents) ->
    fakeContext = @_createFakeContext domainEvents
    new Aggregate fakeContext, 'Aggregate', AggregateClass


  _createFakeContext: (domainEvents) ->
    name: 'eventric-testing'
    getDomainEvent: (name) -> domainEvents[name]


module.exports = new AggregateFactory