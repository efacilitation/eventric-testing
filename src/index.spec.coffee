describe 'eventricTesting', ->

  eventricTesting = require './'

  beforeEach ->
    handler = sandbox.stub()

  describe '#restore', ->

    it 'should restore all objectsToRestore', ->
      wiredRemote  = eventricTesting.wiredRemote 'context'
      sandbox.spy wiredRemote, '$restore'
      eventricTesting.restore()
      expect(wiredRemote.$restore).to.have.been.calledOnce
