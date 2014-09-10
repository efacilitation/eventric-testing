eventric        = require 'eventric'
Remote          = require 'eventric/src/remote'
remoteInMemory  = require 'eventric/src/remote_inmemory'

domainEventFactory    = require './domain_event_factory'
stubFactory           = require './stub_factory'

class RemoteFactory

  wiredRemote: (contextName, domainEvents) ->

    wiredRemote = new Remote contextName
    wiredRemote._domainEvents = []
    wiredRemote.addClient 'inmemory', remoteInMemory.client
    wiredRemote.set 'default client', 'inmemory'

    wiredRemote.$populateWithDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      @_domainEvents.push @_createDomainEvent domainEventName, aggregateId, domainEventPayload


    wiredRemote.$emitDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      domainEvent = @_createDomainEvent domainEventName, aggregateId, domainEventPayload
      remoteInMemory.endpoint.publish contextName, domainEvent.name, domainEvent
      if domainEvent.aggregate
        remoteInMemory.endpoint.publish contextName, domainEvent.name, domainEvent.aggregate.id, domainEvent
      @_domainEvents.push domainEvent


    wiredRemote._createDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      DomainEventClass = domainEvents[domainEventName]
      if not DomainEventClass
        throw new Error 'Trying to populate wired remote with unknown domain event ' + domainEventName
      domainEventFactory.createDomainEvent contextName, domainEventName, DomainEventClass, aggregateId, domainEventPayload


    wiredRemote.findDomainEventsByName = (names) ->
      names = [names] unless names instanceof Array
      then: (callback) =>
        callback @_domainEvents.filter (x) -> names.indexOf(x.name) > -1
      catch: ->


    wiredRemote.findDomainEventsByNameAndAggregateId = (names, aggregateIds) ->
      names = [names] unless names instanceof Array
      aggregateIds = [aggregateIds] unless aggregateIds instanceof Array
      then: (callback) =>
        callback @_domainEvents.filter (x) ->
          names.indexOf(x.name) > -1 and x.aggregate and aggregateIds.indexOf(x.aggregate.id) > -1
      catch: ->


    wiredRemote


module.exports = new RemoteFactory
