describe 'eventricTesting', ->

  eventric = require 'eventric'

  eventricTesting = require './'

  describe '#destroy', ->

    it 'should make contexts inoperative', ->
      context1 = eventric.context 'context1'

      context1.initialize()
      .then ->
        originalCommandFunction = context1.command
        originalSaveDomainEventFunction = context1.getDomainEventsStore().saveDomainEvent
        originalPublishDomainEventFunction = context1.getEventBus().publishDomainEvent
        eventricTesting.destroy()
        .then ->
          expect(context1.command).not.to.equal originalCommandFunction
          expect(context1.getDomainEventsStore().saveDomainEvent).not.to.equal originalSaveDomainEventFunction
          expect(context1.getEventBus().publishDomainEvent).not.to.equal originalPublishDomainEventFunction


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
        eventricTesting.destroy()
      .then ->
        expect(context1.destroy).to.have.been.called
        expect(context2.destroy).to.have.been.called


    it 'should destroy all wired remotes', ->
      wiredRemote1  = eventricTesting.wiredRemote 'context1'
      wiredRemote2  = eventricTesting.wiredRemote 'context2'
      sandbox.spy wiredRemote1, '$destroy'
      sandbox.spy wiredRemote2, '$destroy'
      eventricTesting.destroy()
      .then ->
        expect(wiredRemote1.$destroy).to.have.been.calledOnce
        expect(wiredRemote2.$destroy).to.have.been.calledOnce
