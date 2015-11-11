eventric = require 'eventric'

aggregateFactory = require './aggregate_factory'
fakePromise = require './fake_promise'
eventualConsistencyUtilities = require './eventual_consistency_utilities'
remoteFactory = require './remote_factory'

wiredRemotes = []

class EventricTesting

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


  wiredRemote: (args...) ->
    wiredRemote = remoteFactory.wiredRemote args...
    wiredRemotes.push wiredRemote
    wiredRemote


  destroy: ->
    contexts = @_getRegisteredEventricContexts()
    contexts.forEach @_makeContextInoperative
    destroyContextsPromise = Promise.all contexts.map (context) -> context.destroy()
    destroyRemotesPromise = Promise.all wiredRemotes.map (wiredRemote) -> wiredRemote.$destroy()
    destroyRemotesPromise = destroyRemotesPromise.then -> wiredRemotes = []

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
    return Object.keys(eventric._contexts).map (contextName) ->
      eventric._contexts[contextName]


  _makeContextInoperative: (context) ->
    context.command = -> Promise.resolve eventric.generateUuid()
    context.getEventBus().publishDomainEvent = -> Promise.resolve()
    domainEventsStore = context.getDomainEventsStore()
    if domainEventsStore
      domainEventsStore.saveDomainEvent = -> Promise.resolve()


module.exports = new EventricTesting
