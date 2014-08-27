aggregateFactory  = require './aggregate_factory'
stubFactory       = require './stub_factory'

class ProjectionFactory

  wiredProjection: (ProjectionClass, domainEvents) ->
    projection = @_instantiateProjection ProjectionClass
    @_wireProjection projection, domainEvents
    projection


  _instantiateProjection: (ProjectionClass) ->
    projection = new ProjectionClass
    projection.$store = mongodb: @_createProjectionStoreMongoDb()
    projection.$adapter = stubFactory.stub()
    projection


  _wireProjection: (projection, domainEvents) ->
    class FakeAggregateClass
    fakeAggregate = aggregateFactory.instantiateAggregateWithFakeContext FakeAggregateClass, domainEvents
    originalHandleDomainEvent = fakeAggregate._handleDomainEvent
    fakeAggregate._handleDomainEvent = -> originalHandleDomainEvent.apply {root: projection}, arguments
    projection.$emitDomainEvent = (eventName, aggregateId, payload) ->
      fakeAggregate.id = aggregateId
      if not projection["handle#{eventName}"]
        throw new Error "Domain Event Handler has not subscribed to domain event #{eventName}"
      fakeAggregate.emitDomainEvent.call fakeAggregate, eventName, payload
    projection


  _createProjectionStoreMongoDb: ->
    projectionStoreMongoDb =
      find: stubFactory.stub()
      findOne: stubFactory.stub()
      update: stubFactory.stub()
      upsert: stubFactory.stub()
      insert: stubFactory.stub()
      count: stubFactory.stub()
      save: stubFactory.stub()
      remove: stubFactory.stub()
    for key of projectionStoreMongoDb
      stubFactory.configureReturnValue projectionStoreMongoDb[key], null
    projectionStoreMongoDb


  # TODO: This function is used for domain event handlers
  # TODO: Refactor to something less crazy to support domain event handlers testing
  ###
  Object.keys(domainEventHandlerObject).forEach (key) ->
    if typeof domainEventHandlerObject[key] is 'function'
      domainEventHandlerObject["handle#{key}"] = (domainEvent) ->
        domainEventHandlerObject[key].call this, domainEvent, ->
  ###


module.exports = new ProjectionFactory