eventric  = require 'eventric'

class AggregateFactory

  createAggregate: ({aggregateClass, domainEvents, createParams}) ->
    context = eventric.context "EventricTesting-#{Math.random()}"
    context.addAggregate 'TestAggregate', aggregateClass
    context.defineDomainEvents domainEvents
    context.addCommandHandlers
      CreateAggregate: ->
        @$aggregate.create 'TestAggregate', createParams

    context.initialize()
    .then ->
      context.command 'CreateAggregate'
    .then (aggregate) ->
      context.destroy()
      .then ->
        return aggregate


module.exports = new AggregateFactory
