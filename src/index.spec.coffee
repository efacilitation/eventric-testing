describe 'eventricTesting', ->

  eventricTesting = require './'

  beforeEach ->
    handler = sandbox.stub()

  describe '#restore', ->

    it 'should destroy all wired remotes', ->
      wiredRemote  = eventricTesting.wiredRemote 'context'
      sandbox.spy wiredRemote, '$destroy'
      eventricTesting.destroy()
      expect(wiredRemote.$destroy).to.have.been.calledOnce
