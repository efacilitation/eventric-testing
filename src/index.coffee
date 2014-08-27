eventric                    = require 'eventric'

stubFactory                 = require './stub_factory'
aggregateFactory            = require './aggregate_factory'
fakePromise                 = require './fake_promise'
commandQueryFactory         = require './command_query_factory'
projectionFactory           = require './projection_factory'
domainEventHandlersFactory  = require './domain_event_handlers_factory'


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


  repositoryStub: (args...) ->
    commandQueryFactory.repositoryStub args...


  wiredDomainEventHandlers: (args...) ->
    domainEventHandlersFactory.wiredDomainEventHandlers args...


  projectionStoreMongoDbStub: (args...) ->
    projectionFactory.mongoDbStoreStub args...


module.exports = eventric.testing
