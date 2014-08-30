![eventric logo](https://raw.githubusercontent.com/wiki/efacilitation/eventric/eventric_logo.png)

## eventric-testing

Testing is important. This library supports you in writing unit tests and feature specs more easily.


### API



### setStubMethods

Params:
- *stubMethod* { Function } - Factory method for creating stubs
- *configureReturnValueMethod* { Function } - Function to configure a return value of a stub

Configure the stub methods eventric-testing should use.

### resolve

Params:
- *arguments* { * } - List of arguments which are passed to the success handler

Returns a promise like object which synchronously executes the success handler provided via .then()

### reject

Params:
- *arguments* { * } - List of arguments which are passed to the error handler

Returns a promise like object which synchronously executes the error handler provided via .catch()

### resolveAsync

Params:
- *arguments* { * } - List of arguments which are passed to the success handler

Returns a promise like object which asynchronously executes the success handler provided via .then()
The execution of the success handler is scheduled via setTimeout(fn, 0);

### rejectAsync

Params:
- *arguments* { * } - List of arguments which are passed to the error handler

Returns a promise like object which asynchronously executes the error handler provided via .catch()
The execution of the error handler is scheduled via setTimeout(fn, 0);

### fakeAggregate

Params:
- *AggregateClass* { Function } - Constructor function (~Class) used for instantiation

Creates an instance of the given aggregate class and injects a $emitDomainEvent stub into the instance.

### wiredAggregate

Params:
- *AggregateClass* { Function } - Constructor function (~Class) used for aggregate instantiation
- *domainEvents* { Object } - Object of associated domainEvents with name as key and constructor as value

Creates an instance of the given aggregate class which can emit domain events to itself and handle them.
The passed in domain events object is used to verify event name correctness and to construct the event payload.

### wiredCommandHandler

Params:
- *commandHandler* { Function } - Command handler function

Creates a with stubs injected version of the given command handler function.
The following eventric services for command handler are stubbed:
$adapter, $repository, $domainService, $query, $projectionStore, $emitDomainEvent
$repository and $projectionStore also return stubbed instances when called.
The services are also exposed on the created function itself for easier testing.

### wiredQueryHandler

Params:
- *queryHandler* { Function } - Query handler function

Creates a with stubs injected version of the given query handler function.
The following eventric services for query handler are stubbed:
$adapter, $repository, $domainService, $query, $projectionStore, $emitDomainEvent
$repository and $projectionStore also return stubbed instances when called.
The services are also exposed on the created function itself for easier testing.

### wiredProjection

Params:
- *ProjectionClass* { Function } - Constructor function (~Class) used for instantiation
- *projectionParams* { Object } - Object of params passed to the projection's initialize function (optional)
- *domainEvents* { Object } - Object of associated domainEvents with name as key and constructor as value

Creates an instance of the given projection class which can emit domain events to itself and handle them.
The passed in domain events object is used to verify event name correctness and to construct the event payload.

### repositoryStub



Creates a stubbed version of a repository.
The stubbed functions are: findById(), create() and save().
All of them return a synchronously resolving promise like object.

### wiredRemote

Params:
- *contextName* { String } - Name of the context the remote is used for
- *domainEvents* { Object } - Object of associated domainEvents with name as key and constructor as value

Creates a with stubs injected version of remote for a context.
The remote is capable of being (pre-)populated with domain events and publishing domain events to subscribers.
The pre-population is useful to verify that projections are correctly built for domain events occurred in the past.

### wiredDomainEventHandlers

Params:
- *domainEventHandlers* { Object } - Domain event handlers object
- *domainEvents* { Object } - Domain event handlers object

Creates an object which is capable to emit domain

### projectionStoreMongoDbStub



Creates a stubbed version of a mongo db projection store.
The returned object mostly resembles the functions available on a mongo db collection.

### createDomainEvent

Params:
- *contextName* { String } - Name of context the event lives in
- *domainEventName* { String } - Name of the domain event
- *DomainEventClass* { Function } - Constructor function (~Class) used for the domain event payload
- *aggregateId* { String } - Aggregate id of the event
- *domainEventPayload* { Object } - Payload which is passed to the domain event constructor

Creates an instance of eventric's DomainEvent using the provided metadata, constructor and payload.

  ```javascript
  var SomethingHappened = function(params) {
    this.foo = params.foo
  }
  var domainEvent = eventricTesting.createDomainEvent('example', 'SomethingHappened', SomethingHappened, '1234', {foo: 'bar'});



## License

MIT

Copyright (c) 2013-2014 SixSteps Team, eFa GmbH
