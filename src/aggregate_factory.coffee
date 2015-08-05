eventric  = require 'eventric'

class AggregateFactory

  createAggregate: (AggregateClass, domainEvents) ->
    context = eventric.context "EventricTesting-#{Math.random()}"
    context.addAggregate 'test', AggregateClass
    context.defineDomainEvents domainEvents
    context.addCommandHandlers CreateAggregate: -> @$aggregate.create 'test'
    context.initialize()
    .then ->
      context.command 'CreateAggregate'
    .then (aggregate) ->
      context.destroy()
      .then ->
        return aggregate


module.exports = new AggregateFactory
