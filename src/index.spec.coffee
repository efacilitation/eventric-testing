describe 'eventricTesting', ->

  eventric = require 'eventric'
  eventricTesting = require './'

  describe '#destroy', ->

    it 'should throw an error given no eventric instance', ->
      expect(-> eventricTesting.destroy null).to.throw Error, /eventric instance missing/


    it 'should make contexts inoperative', ->
      context1 = eventric.context 'context1'

      context1.initialize()
      .then ->
        originalCommandFunction = context1.command
        originalSaveDomainEventFunction = context1.getDomainEventsStore().saveDomainEvent
        originalPublishDomainEventFunction = context1.getEventBus().publishDomainEvent
        eventricTesting.destroy eventric
        .then ->
          expect(context1.command).not.to.equal originalCommandFunction
          expect(context1.getDomainEventsStore().saveDomainEvent).not.to.equal originalSaveDomainEventFunction
          expect(context1.getEventBus().publishDomainEvent).not.to.equal originalPublishDomainEventFunction


    it 'should replace the command function of a context with a function resolving with a fake aggregate id', ->
      context1 = eventric.context 'context1'
      context1.initialize()
      .then ->
        eventricTesting.destroy eventric
      .then ->
        context1.command 'Foo'
      .then (aggregateId) ->
        expect(aggregateId).to.be.a 'string'


    it 'should destroy all contexts', ->
      context1 = eventric.context 'context1'
      context2 = eventric.context 'context2'
      sandbox.stub context1, 'destroy'
      sandbox.stub context2, 'destroy'

      Promise.all [
        context1.initialize()
        context2.initialize()
      ]
      .then ->
        eventricTesting.destroy eventric
      .then ->
        expect(context1.destroy).to.have.been.called
        expect(context2.destroy).to.have.been.called


    it 'should destroy all fake remote contexts', ->
      fakeRemoteContext1 = eventricTesting.setupFakeRemoteContext eventric, 'context1'
      fakeRemoteContext2 = eventricTesting.setupFakeRemoteContext eventric, 'context2'
      sandbox.spy fakeRemoteContext1, '$destroy'
      sandbox.spy fakeRemoteContext2, '$destroy'
      eventricTesting.destroy eventric
      .then ->
        expect(fakeRemoteContext1.$destroy).to.have.been.calledOnce
        expect(fakeRemoteContext2.$destroy).to.have.been.calledOnce
