eventric                    = require 'eventric'

stubFactory                 = require './stub_factory'
aggregateFactory            = require './aggregate_factory'
fakePromise                 = require './fake_promise'
commandQueryFactory         = require './command_query_factory'
projectionFactory           = require './projection_factory'
domainEventHandlersFactory  = require './domain_event_handlers_factory'
remoteFactory               = require './remote_factory'
domainEventFactory          = require './domain_event_factory'

wiredRemotes = []

eventric.testing =

  ###*
  * @name setStubMethods
  * @param {Function} stubMethod Factory method for creating stubs
  * @param {Function} configureReturnValueMethod Function to configure a return value of a stub
  *
  * @description
  *
  * Configure the stub methods eventric-testing should use.
  *
  * Example for use of eventric-testing with sinon stubs:
  * ```javascript
  * beforeEach(function() {
  *   eventricTesting.setStubMethods(sandbox.stub, function(stub, returnValue) { stub.returns(returnValue); });
  * });
  * ```
  ###
  setStubMethods: (stubMethod, configureReturnValueMethod) ->
    stubFactory.setStubMethod stubMethod
    stubFactory.setConfigureReturnValueMethod configureReturnValueMethod


  ###*
  * @name resolve
  * @param {*} [arguments] List of arguments which are passed to the success handler
  *
  * @description
  *
  * Returns a promise like object which synchronously executes the success handler provided via .then(). If another promise is returned by the handler function, this promise will be returned.
  *
  * Example:
  * ```javascript
  * var loadUser = eventricTesting.resolve({username: 'John Doe'});
  * loadUser.then(function(user) {
  *   console.log(user);
  * });
  * ```
  ###
  resolve: (args...) ->
    fakePromise.resolve args...


  ###*
  * @name reject
  * @param {*} [arguments] List of arguments which are passed to the error handler
  *
  * @description
  *
  * Returns a promise like object which synchronously executes the error handler provided via .catch(). If another promise is returned by the handler function, this promise will be returned.
  *
  * Example:
  * ```javascript
  * var loadUser = eventricTesting.reject(new Error('User could not be loaded'));
  * loadUser.error(function(error) {
  *   console.log(error);
  * });
  * ```
  ###
  reject: (args...) ->
    fakePromise.reject args...


  ###*
  * @name resolveAsync
  * @param {*} [arguments] List of arguments which are passed to the success handler
  *
  * @description
  *
  * Returns a promise like object which asynchronously executes the success handler provided via .then()
  * The execution of the success handler is scheduled via setTimeout(fn, 0);
  *
  * Example:
  * ```javascript
  * var loadUser = eventricTesting.resolveAsync({username: 'John Doe'});
  * loadUser.then(function(user) {
  *   console.log(user);
  * });
  * ```
  ###
  resolveAsync: (args...) ->
    fakePromise.resolveAsync args...


  ###*
  * @name rejectAsync
  * @param {*} [arguments] List of arguments which are passed to the error handler
  *
  * @description
  *
  * Returns a promise like object which asynchronously executes the error handler provided via .catch()
  * The execution of the error handler is scheduled via setTimeout(fn, 0);
  *
  * Example:
  * ```javascript
  * var loadUser = eventricTesting.reject(new Error('User could not be loaded'));
  * loadUser.error(function(error) {
  *   console.log(error);
  * });
  * ```
  ###
  rejectAsync: (args...) ->
    fakePromise.rejectAsync args...


  ###*
  * @name fakeAggregate
  * @param {Function} AggregateClass Constructor function (~Class) used for instantiation
  *
  * @description
  *
  * Creates an instance of the given aggregate class and injects a $emitDomainEvent stub into the instance.
  *
  ###
  fakeAggregate: (args...) ->
    aggregateFactory.fakeAggregate args...


  ###*
  * @name wiredAggregate
  * @param {Function} AggregateClass Constructor function (~Class) used for aggregate instantiation
  * @param {Object} domainEvents Object of associated domainEvents with name as key and constructor as value
  *
  * @description
  *
  * Creates an instance of the given aggregate class which can emit domain events to itself and handle them.
  * The passed in domain events object is used to verify event name correctness and to construct the event payload.
  *
  * Example:
  * ```javascript
  * var Aggregate = function() {
  *   this.create = function(callback) {
  *     this.$emitDomainEvent('AggregateCreated', {foo: 'bar'});
  *   };
  *   this.handleAggregateCreated = function(domainEvent) {
  *     this.foo = domainEvent.payload.foo;
  *   };
  * };
  * var domainEvents = {
  *   AggregateCreated: function(params) {
  *     this.foo = params.foo;
  *   }
  * }
  *
  * aggregate = eventricTesting.wiredAggregate(Aggregate, domainEvents);
  * aggregate.create(function() {});
  * expect(aggregate.foo).to.equal('bar');
  * ```
  ###
  wiredAggregate: (args...) ->
    aggregateFactory.wiredAggregate args...


  ###*
  * @name wiredCommandHandler
  * @param {Function} commandHandler Command handler function
  *
  * @description
  *
  * Creates a with stubs injected version of the given command handler function.
  * The following eventric services for command handler are stubbed:
  * $adapter, $repository, $domainService, $query, $projectionStore, $emitDomainEvent
  * $repository and $projectionStore also return stubbed instances when called.
  * The services are also exposed on the created function itself for easier testing.
  *
  * Example:
  * ```javascript
  * var handlers = {
  *   DoSomething: function(params) {
  *     this.$repository('Aggregate').findById(params.id)
  *     .then(function(aggregate) {
  *       aggregate.doSomething();
  *     });
  *     // ...
  *   }
  * };
  * var doSomething = eventricTesting.wiredCommandHandler(handlers.DoSomething);
  * doSomething({id: 1234});
  * expect(doSomething.$repository.findById).to.have.been.calledWith(1234);
  * ```
  ###
  wiredCommandHandler: (args...) ->
    commandQueryFactory.wiredCommandHandler args...


  ###*
  * @name wiredQueryHandler
  * @param {Function} queryHandler Query handler function
  *
  * @description
  *
  * Creates a with stubs injected version of the given query handler function.
  * The following eventric services for query handler are stubbed:
  * $adapter, $repository, $domainService, $query, $projectionStore, $emitDomainEvent
  * $repository and $projectionStore also return stubbed instances when called.
  * The services are also exposed on the created function itself for easier testing.
  *
  * Example:
  * ```javascript
  * var handlers = {
  *   findSomething: function(params) {
  *     this.$repository('Aggregate').findById(params.id)
  *     .then(function(aggregate) {
  *       return aggregate;
  *     });
  *   }
  * };
  * var findSomething = eventricTesting.wiredQueryHandler(handlers.findSomething);
  * findSomething({id: 1234});
  * expect(findSomething.$repository.findById).to.have.been.calledWith(1234);
  * ```
  ###
  wiredQueryHandler: (args...) ->
    commandQueryFactory.wiredQueryHandler args...


  ###*
  * @name wiredProjection
  * @param {Function} ProjectionClass Constructor function (~Class) used for instantiation
  * @param {Object} projectionParams Object of params passed to the projection's initialize function (optional)
  * @param {Object} domainEvents Object of associated domainEvents with name as key and constructor as value
  *
  * @description
  *
  * Creates an instance of the given projection class which can emit domain events to itself and handle them.
  * The passed in domain events object is used to verify event name correctness and to construct the event payload.
  *
  * Example:
  * ```javascript
  * var AggregateProjection = function() {
  *   this.aggregateCount = 0;
  *   this.handleAggregateCreated = function(domain) {
  *     this.aggregateCount++;
  *   };
  * };
  * var domainEvents = {
  *   AggregateCreated: function(params) {}
  * }
  *
  * projection = eventricTesting.wiredProjection(AggregateProjection, domainEvents);
  * projection.$emitDomainEvent('AggregateCreated', {});
  * expect(projection.aggregateCount).to.equal(1);
  * ```
  * Note: This works for both normal projections and remote projections.
  ###
  wiredProjection: (args...) ->
    projectionFactory.wiredProjection args...


  ###*
  * @name aggregateStub
  *
  * @description
  *
  * Creates a stubbed version of a aggregate.
  * The stubbed functions are: create() and load().
  * All of them return a synchronously resolving promise like object.
  *
  * Example:
  * ```javascript
  * var aggregate = eventricTesting.aggregateStub()
  * aggregate.save().then(function() {
  *   console.log('got saved');
  * });
  * ```
  ###
  aggregateStub: (args...) ->
    commandQueryFactory.aggregateStub args...


  ###*
  * @name wiredRemote
  * @param {String} contextName Name of the context the remote is used for
  * @param {Object} domainEvents Object of associated domainEvents with name as key and constructor as value
  *
  * @description
  *
  * Creates a with stubs injected version of remote for a context.
  * The remote is capable of being (pre-)populated with domain events and publishing domain events to subscribers.
  * The pre-population is useful to verify that projections are correctly built for domain events occurred in the past.
  *
  * Example:
  * ```javascript
  * var domainEvents = {
  *   SomethingCreated: function() {},
  *   SomethingModified: function() {}
  * };
  * var RemoteProjection = function() {
  *   this.actionLog = [];
  *   this.handleSomethingCreated: function() {
  *     this.actionLog.push('created');
  *   }
  *   this.SomethingModified: function() {
  *     this.actionLog.push('modified');
  *   }
  * };
  * var wiredRemote = eventricTesting.wiredRemote('example', domainEvents);
  * wiredRemote.$populateWithDomainEvent('SomethingCreated', {});
  * wiredRemote.$populateWithDomainEvent('SomethingModified', {});
  * wiredRemote.addProjection('RemoteProjection', RemoteProjection);
  * wiredRemote.initializeProjectionInstance('RemoteProjection')
  * .then(function(projectionId) {
  *   projection = wiredRemote.getProjectionInstance(projectionId);
  *   expect(projection.actionLog).to.deep.equal(['created', 'modified']);
  *   wiredRemote.$emitDomainEvent('SomethingCreated', {});
  *   return wiredRemote.$waitForEmitDomainEvent().then(function() {
  *     expect(projection.actionLog.length).to.equal(3);
  *   });
  * });
  * ```
  ###
  wiredRemote: (args...) ->
    wiredRemote = remoteFactory.wiredRemote args...
    wiredRemotes.push wiredRemote
    wiredRemote


  ###*
  * @name wiredDomainEventHandlers
  * @param {Object} domainEventHandlers Domain event handlers object
  * @param {Object} domainEvents Object of associated domainEvents with name as key and constructor as value
  *
  * @description
  *
  * Creates an object which is capable to emit domain events to itself and let the handler functions handle them.
  *
  * Example:
  * ```javascript
  * var domainEvents = {
  *   SomethingCreated: function() {}
  * };
  * var handlers = {
  *   SomethingCreated: function(domainEvent) {
  *     ...
  *   }
  * };
  * var wiredHandlers = eventricTesting.wiredDomainEventHandlers(handlers);
  * sandbox.stub(wiredHandlers, 'SomethingCreated');
  * wiredHandlers.$emitDomainEvent('SomethingCreated', {});
  * expect(wiredHandlers.SomethingCreated).to.have.been.called();
  * ```
  ###
  wiredDomainEventHandlers: (args...) ->
    domainEventHandlersFactory.wiredDomainEventHandlers args...


  ###*
  * @name projectionStoreMongoDbStub
  *
  * @description
  *
  * Creates a stubbed version of a mongo db projection store.
  * The returned object mostly resembles the functions available on a mongo db collection.
  *
  * Example:
  * ```javascript
  * var projectionStore = eventricTesting.projectionStoreMongoDbStub()
  * projectionStore.upsert().then(function() {
  *   console.log('got saved');
  * });
  * ```
  ###
  projectionStoreMongoDbStub: (args...) ->
    projectionFactory.mongoDbStoreStub args...


  ###*
  * @name createDomainEvent
  * @param {String} contextName Name of context the event lives in
  * @param {String} domainEventName Name of the domain event
  * @param {Function} DomainEventClass Constructor function (~Class) used for the domain event payload
  * @param {String} aggregateId Aggregate id of the event
  * @param {Object} domainEventPayload Payload which is passed to the domain event constructor
  * @description
  *
  * Creates an instance of eventric's DomainEvent using the provided metadata, constructor and payload.
  *
  * Example:
  * ```javascript
  * var SomethingHappened = function(params) {
  *   this.foo = params.foo
  * }
  * var domainEvent = eventricTesting.createDomainEvent('example', 'SomethingHappened', SomethingHappened, '1234', {foo: 'bar'});
  * ```
  ###
  createDomainEvent: (args...) ->
    domainEventFactory.createDomainEvent args...


  ###*
  * @name destroy
  * @description
  *
  * Destroys all wired remotes and removes all registered DomainEventHandlers from the contexts
  *
  * Example:
  * ```javascript
  * afterEach(function() {
  *   eventricTesting.restore()
  * })
  * ```
  ###

  destroy: ->
    for wiredRemote in wiredRemotes
      wiredRemote.$destroy()
    wiredRemotes = []


module.exports = eventric.testing
