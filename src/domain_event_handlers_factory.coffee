aggregateFactory  = require './aggregate_factory'
stubFactory       = require './stub_factory'

class DomainEventHandlersFactory

  wiredDomainEventHandlers: (domainEventHandlers, domainEvents) ->
    eventHandlersProxy = @_createEventHandlersProxy domainEventHandlers
    class FakeAggregateClass
    fakeAggregate = aggregateFactory.instantiateAggregateWithFakeContext FakeAggregateClass, domainEvents
    originalHandleDomainEvent = fakeAggregate._handleDomainEvent
    fakeAggregate._handleDomainEvent = -> originalHandleDomainEvent.apply {root: eventHandlersProxy}, arguments

    eventHandlersProxy.$emitDomainEvent = (eventName, aggregateId, payload) ->
      fakeAggregate.id = aggregateId
      if not eventHandlersProxy["handle#{eventName}"]
        throw new Error "Domain Event Handler has not subscribed to domain event #{eventName}"
      fakeAggregate.emitDomainEvent.call fakeAggregate, eventName, payload

    eventHandlersProxy


  _createEventHandlersProxy: (domainEventHandlers) ->
    eventHandlersProxy = {}
    Object.keys(domainEventHandlers).forEach (key) ->
      if typeof domainEventHandlers[key] is 'function'
        eventHandlersProxy["handle#{key}"] = (domainEvent) ->
          domainEventHandlers[key].call this, domainEvent, ->
    eventHandlersProxy


module.exports = new DomainEventHandlersFactory