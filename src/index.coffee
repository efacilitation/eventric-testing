eventric                    = require 'eventric'

stubFactory                 = require './stub_factory'
aggregateFactory            = require './aggregate_factory'
fakePromise                 = require './fake_promise'
commandQueryFactory         = require './command_query_factory'
projectionFactory           = require './projection_factory'
remoteFactory               = require './remote_factory'
domainEventFactory          = require './domain_event_factory'

wiredRemotes = []

eventric.testing =

  setStubMethods: (stubMethod, configureReturnValueMethod) ->
    stubFactory.setStubMethod stubMethod
    stubFactory.setConfigureReturnValueMethod configureReturnValueMethod


  resolve: (args...) ->
    fakePromise.resolve args...


  reject: (args...) ->
    fakePromise.reject args...


  resolveAsync: (args...) ->
    fakePromise.resolveAsync args...


  rejectAsync: (args...) ->
    fakePromise.rejectAsync args...


  fakeAggregate: (args...) ->
    aggregateFactory.fakeAggregate args...


  wiredAggregate: (args...) ->
    aggregateFactory.wiredAggregate args...


  wiredCommandHandler: (args...) ->
    commandQueryFactory.wiredCommandHandler args...


  wiredQueryHandler: (args...) ->
    commandQueryFactory.wiredQueryHandler args...


  wiredProjection: (args...) ->
    projectionFactory.wiredProjection args...


  aggregateStub: (args...) ->
    commandQueryFactory.aggregateStub args...


  wiredRemote: (args...) ->
    wiredRemote = remoteFactory.wiredRemote args...
    wiredRemotes.push wiredRemote
    wiredRemote


  projectionStoreMongoDbStub: (args...) ->
    projectionFactory.mongoDbStoreStub args...


  createDomainEvent: (args...) ->
    domainEventFactory.createDomainEvent args...


  destroy: ->
    for wiredRemote in wiredRemotes
      wiredRemote.$destroy()
    wiredRemotes = []


  waitForQueryToReturnResult: (args...) ->
    commandQueryFactory.waitForQueryToReturnResult args...


  waitForCommandToResolve: (args...) ->
    commandQueryFactory.waitForCommandToResolve args...


  waitForResult: (args...) ->
    commandQueryFactory.waitForResult args...


module.exports = eventric.testing
