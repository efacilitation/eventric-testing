_                  = require 'lodash'

eventric           = require 'eventric'
Remote             = require 'eventric/src/remote'
remoteInMemory     = require 'eventric/src/remote_inmemory'

domainEventFactory = require './domain_event_factory'
stubFactory        = require './stub_factory'

class RemoteFactory

  wiredRemote: (contextName, domainEvents) ->

    wiredRemote = new Remote contextName
    wiredRemote._domainEvents = []
    wiredRemote._subscriberIds = []
    wiredRemote._commandStubs = []
    wiredRemote.addClient 'inmemory', remoteInMemory.client
    wiredRemote.set 'default client', 'inmemory'

    wiredRemote.$populateWithDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      @_domainEvents.push @_createDomainEvent domainEventName, aggregateId, domainEventPayload


    wiredRemote.$emitDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      domainEvent = @_createDomainEvent domainEventName, aggregateId, domainEventPayload
      remoteInMemory.endpoint.publish contextName, domainEvent
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


    originalSubscribeToAllDomainEvents = wiredRemote.subscribeToAllDomainEvents
    wiredRemote.subscribeToAllDomainEvents = ->
      id = originalSubscribeToAllDomainEvents.apply @, arguments
      @_subscriberIds.push id
      id


    originalSubscribeToDomainEvent = wiredRemote.subscribeToDomainEvent
    wiredRemote.subscribeToDomainEvent = ->
      id = originalSubscribeToDomainEvent.apply @, arguments
      @_subscriberIds.push id
      id


    originalSubscribeToDomainEventWithAggregateId = wiredRemote.subscribeToDomainEventWithAggregateId
    wiredRemote.subscribeToDomainEventWithAggregateId = ->
      id = originalSubscribeToDomainEventWithAggregateId.apply @, arguments
      @_subscriberIds.push id
      id


    wiredRemote.$restore = ->
      @_domainEvents = []
      for subscriberId in @_subscriberIds
        wiredRemote.unsubscribeFromDomainEvent subscriberId
      @_subscriberIds = []
      @_commandStubs = []


    wiredRemote.$onCommand = (command, payload) ->
      commandStub =
        command: command
        payload: payload
        domainEvents: []
        yieldsDomainEvent: (eventName, aggregateId, payload) ->
          @domainEvents.push
            eventName: eventName
            aggregateId: aggregateId
            payload: payload
          @

      @_commandStubs.push commandStub
      commandStub


    originalCommand = wiredRemote.command
    wiredRemote.command = (command, payload) ->
      filteredCommandStubs = @_commandStubs.filter (commandStub) ->
        return false unless command is commandStub.command
        _.isEqual payload, commandStub.payload

      unless filteredCommandStubs.length
        originalCommand.apply @, arguments
        return

      for filteredCommandStub in filteredCommandStubs
        for domainEvent in filteredCommandStub.domainEvents
          @$emitDomainEvent domainEvent.eventName,
            domainEvent.aggregateId,
            domainEvent.payload


    wiredRemote


module.exports = new RemoteFactory
