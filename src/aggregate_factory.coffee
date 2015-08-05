eventric  = require 'eventric'

class AggregateFactory

  createAggregate: (AggregateClass, domainEvents) ->
    context = eventric.context "EventricTesting-#{Math.random()}"
    context.addAggregate 'TestAggregate', @_createAggregateClassWithFakeCreateFunction AggregateClass
    context.defineDomainEvents domainEvents
    context.addCommandHandlers
      CreateAggregate: ->
        @$aggregate.create 'TestAggregate'

    context.initialize()
    .then ->
      context.command 'CreateAggregate'
    .then (aggregate) ->
      context.destroy()
      .then ->
        return aggregate


  _createAggregateClassWithFakeCreateFunction: (AggregateClass) ->
    WrappedAggregteClass = ->
      aggregateInstance = new AggregateClass
      originalCreate = aggregateInstance.create
      aggregateInstance.create = ->
        aggregateInstance.create = originalCreate
      return aggregateInstance

    return WrappedAggregteClass


module.exports = new AggregateFactory
