![eventric logo](https://raw.githubusercontent.com/wiki/efacilitation/eventric/eventric_logo.png)

## eventric-testing

Testing is important. This library supports you in writing unit tests and feature specs more easily.


### API



#### setStubMethods

Params:
- *stubMethod* { Function } - Factory method for creating stubs
- *configureReturnValueMethod* { Function } - Function to configure a return value of a stub

Configure the stub methods eventric-testing should use.

Example for use of eventric-testing with sinon stubs:
```javascript
beforeEach(function() {
  eventricTesting.setStubMethods(sandbox.stub, function(stub, returnValue) { stub.returns(returnValue); });
});
```
#### resolve

Params:
- *arguments* { * } - List of arguments which are passed to the success handler

Returns a promise like object which synchronously executes the success handler provided via .then()

Example:
```javascript
var loadUser = eventricTesting.resolve({username: 'John Doe});
loadUser.then(function(user) {
  console.log(user);
});
```
#### reject

Params:
- *arguments* { * } - List of arguments which are passed to the error handler

Returns a promise like object which synchronously executes the error handler provided via .catch()

Example:
```javascript
var loadUser = eventricTesting.reject(new Error('User could not be loaded'));
loadUser.error(function(error) {
  console.log(error);
});
```
#### resolveAsync

Params:
- *arguments* { * } - List of arguments which are passed to the success handler

Returns a promise like object which asynchronously executes the success handler provided via .then()
The execution of the success handler is scheduled via setTimeout(fn, 0);

Example:
```javascript
var loadUser = eventricTesting.resolveAsync({username: 'John Doe});
loadUser.then(function(user) {
  console.log(user);
});
```
#### rejectAsync

Params:
- *arguments* { * } - List of arguments which are passed to the error handler

Returns a promise like object which asynchronously executes the error handler provided via .catch()
The execution of the error handler is scheduled via setTimeout(fn, 0);

Example:
```javascript
var loadUser = eventricTesting.reject(new Error('User could not be loaded'));
loadUser.error(function(error) {
  console.log(error);
});
```
#### fakeAggregate

Params:
- *AggregateClass* { Function } - Constructor function (~Class) used for instantiation

Creates an instance of the given aggregate class and injects a $emitDomainEvent stub into the instance.
#### wiredAggregate

Params:
- *AggregateClass* { Function } - Constructor function (~Class) used for aggregate instantiation
- *domainEvents* { Object } - Object of associated domainEvents with name as key and constructor as value

Creates an instance of the given aggregate class which can emit domain events to itself and handle them.
The passed in domain events object is used to verify event name correctness and to construct the event payload.

Example:
```javascript
var Aggregate = function() {
  this.create = function(callback) {
    this.$emitDomainEvent('AggregateCreated', {foo: 'bar'});
  };
  this.handleAggregateCreated = function(domainEvent) {
    this.foo = domainEvent.payload.foo;
  };
};
var domainEvents = {
  AggregateCreated: function(params) {
    this.foo = params.foo;
  }
}

aggregate = eventricTesting.wiredAggregate(Aggregate, domainEvents);
aggregate.create(function() {});
expect(aggregate.foo).to.equal('bar');
```
#### wiredCommandHandler

Params:
- *commandHandler* { Function } - Command handler function

Creates a with stubs injected version of the given command handler function.
The following eventric services for command handler are stubbed:
$adapter, $repository, $domainService, $query, $projectionStore, $emitDomainEvent
$repository and $projectionStore also return stubbed instances when called.
The services are also exposed on the created function itself for easier testing.

Example:
```javascript
var handlers = {
  DoSomething: function(params) {
    this.$repository('Aggregate').findById(params.id)
    .then(function(aggregate) {
      aggregate.doSomething();
    });
    // ...
  }
};
var doSomething = eventricTesting.wiredCommandHandler(handlers.DoSomething);
doSomething({id: 1234});
expect(doSomething.$repository.findById).to.have.been.calledWith(1234);
```
#### wiredQueryHandler

Params:
- *queryHandler* { Function } - Query handler function

Creates a with stubs injected version of the given query handler function.
The following eventric services for query handler are stubbed:
$adapter, $repository, $domainService, $query, $projectionStore, $emitDomainEvent
$repository and $projectionStore also return stubbed instances when called.
The services are also exposed on the created function itself for easier testing.

Example:
```javascript
var handlers = {
  findSomething: function(params) {
    this.$repository('Aggregate').findById(params.id)
    .then(function(aggregate) {
      return aggregate;
    });
  }
};
var findSomething = eventricTesting.wiredQueryHandler(handlers.findSomething);
findSomething({id: 1234});
expect(findSomething.$repository.findById).to.have.been.calledWith(1234);
```
#### wiredProjection

Params:
- *ProjectionClass* { Function } - Constructor function (~Class) used for instantiation
- *projectionParams* { Object } - Object of params passed to the projection's initialize function (optional)
- *domainEvents* { Object } - Object of associated domainEvents with name as key and constructor as value

Creates an instance of the given projection class which can emit domain events to itself and handle them.
The passed in domain events object is used to verify event name correctness and to construct the event payload.

Example:
```javascript
var AggregateProjection = function() {
  this.aggregateCount = 0;
  this.handleAggregateCreated = function(domain) {
    this.aggregateCount++;
  };
};
var domainEvents = {
  AggregateCreated: function(params) {}
}

projection = eventricTesting.wiredProjection(AggregateProjection, domainEvents);
projection.$emitDomainEvent('AggregateCreated', {});
expect(projection.aggregateCount).to.equal(1);
```
Note: This works for both normal projections and remote projections.
#### repositoryStub



Creates a stubbed version of a repository.
The stubbed functions are: findById(), create() and save().
All of them return a synchronously resolving promise like object.

Example:
```javascript
var repository = eventricTesting.repositoryStub()
repository.save().then(function() {
  console.log('got saved');
});
```
#### wiredRemote

Params:
- *contextName* { String } - Name of the context the remote is used for
- *domainEvents* { Object } - Object of associated domainEvents with name as key and constructor as value

Creates a with stubs injected version of remote for a context.
The remote is capable of being (pre-)populated with domain events and publishing domain events to subscribers.
The pre-population is useful to verify that projections are correctly built for domain events occurred in the past.

Example:
```javascript
var domainEvents = {
  SomethingCreated: function() {},
  SomethingModified: function() {}
};
var RemoteProjection = function() {
  this.actionLog = [];
  this.handleSomethingCreated: function() {
    this.actionLog.push('created');
  }
  this.SomethingModified: function() {
    this.actionLog.push('modified');
  }
};
var wiredRemote = eventricTesting.wiredRemote('example', domainEvents);
wiredRemote.$populateWithDomainEvent('SomethingCreated', {});
wiredRemote.$populateWithDomainEvent('SomethingModified', {});
wiredRemote.addProjection('RemoteProjection', RemoteProjection);
wiredRemote.initializeProjectionInstance('RemoteProjection')
.then(function(projectionId) {
  projection = wiredRemote.getProjectionInstance(projectionId);
  expect(projection.actionLog).to.deep.equal(['created', 'modified']);
  wiredRemote.$emitDomainEvent('SomethingCreated', {});
  expect(projection.actionLog.length).to.equal(3);
});
```
#### wiredDomainEventHandlers

Params:
- *domainEventHandlers* { Object } - Domain event handlers object
- *domainEvents* { Object } - Domain event handlers object

Creates an object which is capable to emit domain

Example:
```javascript
var handlers = {
  findSomething: function(params) {
    this.$repository('Aggregate').findById(params.id)
    .then(function(aggregate) {
      return aggregate;
    });
  }
};
var findSomething = eventricTesting.wiredQueryHandler(handlers.findSomething);
findSomething({id: 1234});
expect(findSomething.$repository.findById).to.have.been.calledWith(1234);
```
#### projectionStoreMongoDbStub



Creates a stubbed version of a mongo db projection store.
The returned object mostly resembles the functions available on a mongo db collection.

Example:
```javascript
var projectionStore = eventricTesting.projectionStoreMongoDbStub()
projectionStore.upsert().then(function() {
  console.log('got saved');
});
```
#### createDomainEvent

Params:
- *contextName* { String } - Name of context the event lives in
- *domainEventName* { String } - Name of the domain event
- *DomainEventClass* { Function } - Constructor function (~Class) used for the domain event payload
- *aggregateId* { String } - Aggregate id of the event
- *domainEventPayload* { Object } - Payload which is passed to the domain event constructor

Creates an instance of eventric's DomainEvent using the provided metadata, constructor and payload.

Example:
```javascript
var SomethingHappened = function(params) {
  this.foo = params.foo
}
var domainEvent = eventricTesting.createDomainEvent('example', 'SomethingHappened', SomethingHappened, '1234', {foo: 'bar'});
```


## License

MIT

Copyright (c) 2013-2014 SixSteps Team, eFa GmbH
