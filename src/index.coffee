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
    for wiredRemote in wiredRemotes
      wiredRemote.$destroy()
    wiredRemotes = []


  waitForQueryToReturnResult: (args...) ->
    eventualConsistencyUtilities.waitForQueryToReturnResult args...


  waitForCommandToResolve: (args...) ->
    eventualConsistencyUtilities.waitForCommandToResolve args...


  waitForResult: (args...) ->
    eventualConsistencyUtilities.waitForResult args...


module.exports = new EventricTesting
