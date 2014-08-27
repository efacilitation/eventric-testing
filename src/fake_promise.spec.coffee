describe 'fake promise', ->

  fakePromise = require './fake_promise'

  handler = null
  args = null

  beforeEach ->
    handler = sandbox.stub()
    args = foo: 'bar'


  describe '#resolve', ->
    it 'should create a fake promise which is resolved synchronously with the given arguments', ->
      fakePromise.resolve(args).then handler
      expect(handler).to.have.been.calledWith args


  describe '#reject', ->
    it 'should create a fake promise which is rejected synchronously with the given arguments', ->
      fakePromise.reject(args).catch handler
      expect(handler).to.have.been.calledWith args


  describe '#resolveAsync', ->
    it 'should create a fake promise which is resolved asynchronously with the given arguments', (done) ->
      fakePromise.resolveAsync(args).then handler
      setTimeout ->
        expect(handler).to.have.been.calledWith args
        done()
      , 0


  describe '#reject', ->
    it 'should create a fake promise which is rejected asynchronously with the given arguments', (done) ->
      fakePromise.rejectAsync(args).catch handler
      setTimeout ->
        expect(handler).to.have.been.calledWith args
        done()
      , 0
