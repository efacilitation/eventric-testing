equal = require 'deep-equal'
fakePromise = require './fake_promise'
inmemoryRemote = require 'eventric-remote-inmemory'

# TODO: Find a better way to solve the dependency to these eventric internal components
DomainEvent = require 'eventric/src/domain_event'
domainEventIdGenerator = require 'eventric/src/aggregate/domain_event_id_generator'

class RemoteFactory

  setupFakeRemoteContext: (eventric, contextName, domainEvents = {}) ->
    if not eventric
      throw new Error 'eventric instance missing'

    fakeRemoteContext = eventric.remoteContext contextName
    fakeRemoteContext._context = eventric.context contextName

    fakeRemoteContext._mostCurrentEmitOperation = fakePromise.resolve()
    fakeRemoteContext._domainEvents = []
    fakeRemoteContext._subscriberIds = []
    fakeRemoteContext._commandStubs = []
    fakeRemoteContext._context.defineDomainEvents domainEvents
    fakeRemoteContext.setClient inmemoryRemote.client

    fakeRemoteContext.$emitDomainEvent = (domainEventName, aggregateId, domainEventPayload) ->
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


    fakeRemoteContext.$waitForEmitDomainEvent = ->
      fakeRemoteContext._mostCurrentEmitOperation


    fakeRemoteContext._createDomainEvent = (domainEventName, aggregateId, domainEventConstructorParams) ->
      DomainEventPayloadConstructor = fakeRemoteContext._context.getDomainEventPayloadConstructor domainEventName

      if !DomainEventPayloadConstructor
        throw new Error "Tried to create domain event '#{domainEventName}' which is not defined"

      payload = {}
      DomainEventPayloadConstructor.apply payload, [domainEventConstructorParams]

      new DomainEvent
        id: domainEventIdGenerator.generateId()
        name: domainEventName
        aggregate:
          id: aggregateId
          name: 'EventricTesting'
        context: @_context.name
        payload: payload


    fakeRemoteContext.findDomainEventsByName = (names) ->
      names = [names] unless names instanceof Array
      fakePromise.resolve @_domainEvents.filter (x) ->
        names.indexOf(x.name) > -1


    fakeRemoteContext.findDomainEventsByNameAndAggregateId = (names, aggregateIds) ->
      names = [names] unless names instanceof Array
      aggregateIds = [aggregateIds] unless aggregateIds instanceof Array
      fakePromise.resolve @_domainEvents.filter (x) ->
        names.indexOf(x.name) > -1 and x.aggregate and aggregateIds.indexOf(x.aggregate.id) > -1


    originalSubscribeToAllDomainEvents = fakeRemoteContext.subscribeToAllDomainEvents
    fakeRemoteContext.subscribeToAllDomainEvents = ->
      originalSubscribeToAllDomainEvents.apply @, arguments
      .then (subscriberId) =>
        @_subscriberIds.push subscriberId
        subscriberId


    originalSubscribeToDomainEvent = fakeRemoteContext.subscribeToDomainEvent
    fakeRemoteContext.subscribeToDomainEvent = ->
      originalSubscribeToDomainEvent.apply @, arguments
      .then (subscriberId) =>
        @_subscriberIds.push subscriberId
        subscriberId


    originalSubscribeToDomainEventWithAggregateId = fakeRemoteContext.subscribeToDomainEventWithAggregateId
    fakeRemoteContext.subscribeToDomainEventWithAggregateId = ->
      originalSubscribeToDomainEventWithAggregateId.apply @, arguments
      .then (subscriberId) =>
        @_subscriberIds.push subscriberId
        subscriberId


    fakeRemoteContext.$destroy = ->
      @_domainEvents = []
      @_commandStubs = []
      return @_mostCurrentEmitOperation.then =>
        @_mostCurrentEmitOperation = fakePromise.resolve()
        subscriptionRemovals = []
        for subscriberId in @_subscriberIds
          subscriptionRemovals.push fakeRemoteContext.unsubscribeFromDomainEvent subscriberId
        @_subscriberIds = []
        Promise.all subscriptionRemovals


    fakeRemoteContext.$onCommand = (command, payload) ->
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


    originalCommand = fakeRemoteContext.command
    fakeRemoteContext.command = (command, payload) ->
      filteredCommandStubs = @_commandStubs.filter (commandStub) ->
        return command is commandStub.command and equal payload, commandStub.payload

      unless filteredCommandStubs.length
        return Promise.resolve()

      emitDomainEventAsync = (domainEvent) =>
        setTimeout =>
          @$emitDomainEvent domainEvent.eventName,
            domainEvent.aggregateId,
            domainEvent.payload

      for filteredCommandStub in filteredCommandStubs
        for domainEvent in filteredCommandStub.domainEvents
          emitDomainEventAsync domainEvent

      fakePromise.resolveAsync()


    fakeRemoteContext.query = ->
      return Promise.resolve()

    return fakeRemoteContext


module.exports = new RemoteFactory
