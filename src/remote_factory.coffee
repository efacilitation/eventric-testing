_ = require 'lodash'
eventric = require 'eventric'
fakePromise = require './fake_promise'
inmemoryRemote = require 'eventric-remote-inmemory'

class RemoteFactory

  wiredRemote: (contextName, domainEvents) ->
    wiredRemote = eventric.remote contextName
    wiredRemote._mostCurrentEmitOperation = fakePromise.resolve()
    wiredRemote._domainEvents = []
    wiredRemote._subscriberIds = []
    wiredRemote._commandStubs = []
    wiredRemote._context = eventric.context contextName
    wiredRemote._context.defineDomainEvents domainEvents
    wiredRemote.setClient inmemoryRemote.client

    wiredRemote.$populateWithDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      @_domainEvents.push @_createDomainEvent domainEventName, aggregateId, domainEventPayload


    wiredRemote.$emitDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      domainEvent = @_createDomainEvent domainEventName, aggregateId, domainEventPayload
      @_domainEvents.push domainEvent
      endpoint = inmemoryRemote.endpoint
      @_mostCurrentEmitOperation = @_mostCurrentEmitOperation.then ->
        contextEventPublish = endpoint.publish contextName, domainEvent
        contextAndNameEventPublish = endpoint.publish contextName, domainEvent.name, domainEvent
        if domainEvent.aggregate
          fullEventNamePublish = endpoint.publish contextName, domainEvent.name, domainEvent.aggregate.id, domainEvent
          Promise.all([contextEventPublish, contextAndNameEventPublish, fullEventNamePublish])
        else
          Promise.all([contextEventPublish, contextAndNameEventPublish])


    wiredRemote.$waitForEmitDomainEvent = ->
      wiredRemote._mostCurrentEmitOperation


    wiredRemote._createDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
      DomainEventClass = domainEvents[domainEventName]
      if not DomainEventClass
        throw new Error 'Trying to populate wired remote with unknown domain event ' + domainEventName
      wiredRemote._context.createDomainEvent domainEventName, domainEventPayload, {id: aggregateId}


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


    wiredRemote.$destroy = ->
      @_domainEvents = []
      @_commandStubs = []
      @_mostCurrentEmitOperation.then =>
        @_mostCurrentEmitOperation = fakePromise.resolve()
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

      emitDomainEventAsync = (domainEvent) =>
        setTimeout =>
          @$emitDomainEvent domainEvent.eventName,
            domainEvent.aggregateId,
            domainEvent.payload

      for filteredCommandStub in filteredCommandStubs
        for domainEvent in filteredCommandStub.domainEvents
          emitDomainEventAsync domainEvent

      fakePromise.resolve()

    wiredRemote


module.exports = new RemoteFactory
