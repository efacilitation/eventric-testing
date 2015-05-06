eventric    = require 'eventric'
DomainEvent = eventric.DomainEvent

class DomainEventFactory

  createDomainEvent: (contextName, domainEventName, DomainEventClass, aggregateId, domainEventPayload) ->
    payload = {}
    DomainEventClass.apply payload, [domainEventPayload]

    new DomainEvent
      id: eventric.generateUid()
      name: domainEventName
      aggregate:
        id: aggregateId
        name: 'eventric-testing'
      context: contextName
      payload: payload


module.exports = new DomainEventFactory
