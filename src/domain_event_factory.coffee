eventric    = require 'eventric'
DomainEvent = eventric.DomainEvent

class DomainEventFactory

  createDomainEvent: (contextName, domainEventName, DomainEventClass, aggregateId, domainEventPayload) ->
    new DomainEvent
      id: eventric.generateUid()
      name: domainEventName
      aggregate:
        id: aggregateId
        name: 'eventric-testing'
      context: contextName
      payload: new DomainEventClass domainEventPayload


module.exports = new DomainEventFactory
