eventric      = require 'eventric'
Remote        = require 'eventric/src/remote'
DomainEvent   = require 'eventric/src/domain_event'

stubFactory = require './stub_factory'

class RemoteFactory

  wiredRemote: (contextName, domainEvents) ->
    wiredRemote = new Remote contextName
    wiredRemote._domainEvents = []

    wiredRemote.populateWithDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      DomainEventClass = domainEvents[domainEventName]
      if not DomainEventClass
        throw new Error 'Trying to populate wired remote with unknown domain event ' + domainEventName
      domainEvent = new DomainEvent
        id: eventric.generateUid()
        name: domainEventName
        aggregate:
          id: aggregateId
          name: 'eventric-testing'
        context: contextName
        payload: new DomainEventClass domainEventPayload
      @_domainEvents.push domainEvent


    wiredRemote.findDomainEventsByName = (names) ->
      names = [names] unless names instanceof Array
      then: (callback) =>
        callback @_domainEvents.filter (x) -> names.indexOf(x.name) > -1


    wiredRemote.findDomainEventsByNameAndAggregateId = (names, aggregateIds) ->
      names = [names] unless names instanceof Array
      aggregateIds = [aggregateIds] unless aggregateIds instanceof Array
      then: (callback) =>
        callback @_domainEvents.filter (x) ->
          names.indexOf(x.name) > -1 and x.aggregate and aggregateIds.indexOf(x.aggregate.id) > -1


    wiredRemote


module.exports = new RemoteFactory