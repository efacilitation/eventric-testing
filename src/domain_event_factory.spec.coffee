describe 'domain event factory', ->

  domainEventFactory = require './domain_event_factory'

  describe '#createDomainEvent', ->

    it 'should create a domain event with appropriate meta data', ->
      class SomethingHappened
        constructor: (params) ->
          @foo = params.foo
      payload = foo: 'bar'
      domainEvent = domainEventFactory.createDomainEvent 'context', 'SomethingHappened', SomethingHappened, '1234', payload
      expect(domainEvent.name).to.equal 'SomethingHappened'
      expect(domainEvent.aggregate.id).to.equal '1234'
      expect(domainEvent.payload.foo).to.equal 'bar'
      expect(domainEvent.timestamp).to.be.a 'number'
      expect(domainEvent.id).to.be.a 'string'