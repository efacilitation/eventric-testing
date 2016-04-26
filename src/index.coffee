aggregateFactory = require './aggregate_factory'
fakePromise = require './fake_promise'
eventualConsistencyUtilities = require './eventual_consistency_utilities'
remoteFactory = require './remote_factory'

fakeRemoteContexts = []

class EventricTesting

  initialize: (eventric) ->
    @_eventric = eventric
    aggregateFactory.initialize eventric
    remoteFactory.initialize eventric


  resolve: (args...) ->
    fakePromise.resolve args...


  reject: (args...) ->
    fakePromise.reject args...


  resolveAsync: (args...) ->
    fakePromise.resolveAsync args...


  rejectAsync: (args...) ->
    fakePromise.rejectAsync args...


  createAggregate: (args...) ->
    aggregateFactory.createAggregate args...


  setupFakeRemoteContext: (args...) ->
    fakeRemoteContext = remoteFactory.setupFakeRemoteContext args...
    fakeRemoteContexts.push fakeRemoteContext
    fakeRemoteContext


  destroy: ->
    contexts = @_getRegisteredEventricContexts()
    contexts.forEach (context) => @_makeContextInoperative context
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
  _getRegisteredEventricContexts: ->
    return Object.keys(@_eventric._contexts).map (contextName) =>
      @_eventric._contexts[contextName]


  _makeContextInoperative: (context) ->
    context.command = => Promise.resolve @_eventric.generateUuid()
    context.getEventBus().publishDomainEvent = -> Promise.resolve()
    domainEventsStore = context.getDomainEventsStore()
    if domainEventsStore
      domainEventsStore.saveDomainEvent = -> Promise.resolve()


module.exports = new EventricTesting
