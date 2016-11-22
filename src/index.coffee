aggregateFactory = require './aggregate_factory'
fakePromise = require './fake_promise'
eventualConsistencyUtilities = require './eventual_consistency_utilities'
remoteFactory = require './remote_factory'

fakeRemoteContexts = []

class EventricTesting

  resolve: (args...) ->
    fakePromise.resolve args...


  reject: (args...) ->
    fakePromise.reject args...


  rejectAsync: (args...) ->
    fakePromise.rejectAsync args...


  createAggregate: (args...) ->
    aggregateFactory.createAggregate args...


  setupFakeRemoteContext: (args...) ->
    fakeRemoteContext = remoteFactory.setupFakeRemoteContext args...
    fakeRemoteContexts.push fakeRemoteContext
    fakeRemoteContext


  destroy: (eventric) ->
    if not eventric
      throw new Error 'eventric instance missing'

    contexts = @_getRegisteredEventricContexts eventric
    contexts.forEach (context) => @_makeContextInoperative eventric, context
    destroyContextsPromise = Promise.all contexts.map (context) -> context.destroy()
    destroyRemotesPromise = Promise.all fakeRemoteContexts.map (fakeRemoteContext) -> fakeRemoteContext.$destroy()
    destroyRemotesPromise = destroyRemotesPromise.then -> fakeRemoteContexts = []

    return Promise.all [
      destroyContextsPromise
      destroyRemotesPromise
    ]


  waitForQueryToReturnResult: (args...) ->
    eventualConsistencyUtilities.waitForQueryToReturnResult args...


  waitForCommandToResolve: (args...) ->
    eventualConsistencyUtilities.waitForCommandToResolve args...


  waitForResult: (args...) ->
    eventualConsistencyUtilities.waitForResult args...


  # TODO: Consider not to use private members for getting the contexts
  _getRegisteredEventricContexts: (eventric) ->
    return Object.keys(eventric._contexts).map (contextName) ->
      eventric._contexts[contextName]


  _makeContextInoperative: (eventric, context) ->
    context.command = ->
      Promise.resolve eventric.generateUuid()
    context.getEventBus().publishDomainEvent = -> Promise.resolve()
    domainEventsStore = context.getDomainEventsStore()
    if domainEventsStore
      domainEventsStore.saveDomainEvent = -> Promise.resolve()


module.exports = new EventricTesting
