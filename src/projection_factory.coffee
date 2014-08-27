aggregateFactory  = require './aggregate_factory'
stubFactory       = require './stub_factory'

class ProjectionFactory

  wiredProjection: (ProjectionClass, domainEvents) ->
    projection = @_instantiateProjection ProjectionClass
    @_wireProjection projection, domainEvents
    projection


  _instantiateProjection: (ProjectionClass) ->
    projection = new ProjectionClass
    projection.$store = mongodb: @mongoDbStoreStub()
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


  mongoDbStoreStub: ->
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


module.exports = new ProjectionFactory