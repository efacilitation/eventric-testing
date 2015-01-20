_                  = require 'lodash'
eventric           = require 'eventric'
domainEventFactory = require './domain_event_factory'
stubFactory        = require './stub_factory'
fakePromise        = require './fake_promise'

class RemoteFactory

  wiredRemote: (contextName, domainEvents) ->
    wiredRemote = eventric.remote contextName
    wiredRemote._domainEvents = []
    wiredRemote._subscriberIds = []
    wiredRemote._commandStubs = []
    wiredRemote.addClient 'inmemory', eventric.RemoteInMemory.client
    wiredRemote.set 'default client', 'inmemory'

    wiredRemote.$populateWithDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      @_domainEvents.push @_createDomainEvent domainEventName, aggregateId, domainEventPayload


    wiredRemote.$emitDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      domainEvent = @_createDomainEvent domainEventName, aggregateId, domainEventPayload
      eventric.RemoteInMemory.endpoint.publish contextName, domainEvent
      eventric.RemoteInMemory.endpoint.publish contextName, domainEvent.name, domainEvent
      if domainEvent.aggregate
        eventric.RemoteInMemory.endpoint.publish contextName, domainEvent.name, domainEvent.aggregate.id, domainEvent
      @_domainEvents.push domainEvent


    wiredRemote._createDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      DomainEventClass = domainEvents[domainEventName]
      if not DomainEventClass
        throw new Error 'Trying to populate wired remote with unknown domain event ' + domainEventName
      domainEventFactory.createDomainEvent contextName, domainEventName, DomainEventClass, aggregateId, domainEventPayload


    wiredRemote.findDomainEventsByName = (names) ->
      names = [names] unless names instanceof Array
      fakePromise.resolve @_domainEvents.filter (x) ->
        names.indexOf(x.name) > -1


    wiredRemote.findDomainEventsByNameAndAggregateId = (names, aggregateIds) ->
      names = [names] unless names instanceof Array
      aggregateIds = [aggregateIds] unless aggregateIds instanceof Array
      fakePromise.resolve @_domainEvents.filter (x) ->
        names.indexOf(x.name) > -1 and x.aggregate and aggregateIds.indexOf(x.aggregate.id) > -1


    originalSubscribeToAllDomainEvents = wiredRemote.subscribeToAllDomainEvents
    wiredRemote.subscribeToAllDomainEvents = ->
      originalSubscribeToAllDomainEvents.apply @, arguments
      .then (subscriberId) =>
        @_subscriberIds.push subscriberId
        subscriberId


    originalSubscribeToDomainEvent = wiredRemote.subscribeToDomainEvent
    wiredRemote.subscribeToDomainEvent = ->
      originalSubscribeToDomainEvent.apply @, arguments
      .then (subscriberId) =>
        @_subscriberIds.push subscriberId
        subscriberId


    originalSubscribeToDomainEventWithAggregateId = wiredRemote.subscribeToDomainEventWithAggregateId
    wiredRemote.subscribeToDomainEventWithAggregateId = ->
      originalSubscribeToDomainEventWithAggregateId.apply @, arguments
      .then (subscriberId) =>
        @_subscriberIds.push subscriberId
        subscriberId


    wiredRemote.$restore = ->
      @_domainEvents = []
      @_commandStubs = []
      subscriptionRemovals = []
      for subscriberId in @_subscriberIds
        subscriptionRemovals.push wiredRemote.unsubscribeFromDomainEvent subscriberId
      @_subscriberIds = []
      Promise.all subscriptionRemovals


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
        return originalCommand.apply @, arguments

      for filteredCommandStub in filteredCommandStubs
        for domainEvent in filteredCommandStub.domainEvents
          @$emitDomainEvent domainEvent.eventName,
            domainEvent.aggregateId,
            domainEvent.payload

      fakePromise.resolve()

    wiredRemote


module.exports = new RemoteFactory
