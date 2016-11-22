describe 'eventual consistency utilities', ->

  eventric = require 'eventric'

  eventualConsistencyUtilities = require './eventual_consistency_utilities'

  describe '#waitForQueryToReturnResult', ->

    it 'should call the given query on the given context with the given params', ->
      queryStub = sandbox.stub().returns new Promise (resolve) -> resolve {}
      queryParams = {}
      exampleContext = eventric.context 'Example'
      exampleContext.addQueryHandlers getSomething: queryStub
      exampleContext.initialize()
      .then ->
        eventualConsistencyUtilities.waitForQueryToReturnResult exampleContext, 'getSomething', queryParams
      .then ->
        expect(queryStub).to.have.been.calledWith queryParams


    it 'should reject with the query error given a query which rejects with an error', ->
      error = new Error
      exampleContext = eventric.context 'Example'
      exampleContext.addQueryHandlers getSomething: -> new Promise (resolve, reject) -> reject error
      exampleContext.initialize()
      .then ->
        eventualConsistencyUtilities.waitForQueryToReturnResult exampleContext, 'getSomething'
      .catch (receivedError) ->
        expect(receivedError).to.equal error


    it 'should reject with the query error gven a query which rejects with a string', ->
      exampleContext = eventric.context 'Example'
      exampleContext.addQueryHandlers getSomething: -> new Promise (resolve, reject) -> reject 'error'
      exampleContext.initialize()
      .then ->
        eventualConsistencyUtilities.waitForQueryToReturnResult exampleContext, 'getSomething'
      .catch (error) ->
        expect(error).to.equal 'error'


    it 'should resolve with the result given a query callback which resolves with a result', ->
      queryResult = {}
      exampleContext = eventric.context 'Example'
      exampleContext.addQueryHandlers getSomething: ->
        new Promise (resolve) -> resolve queryResult
      exampleContext.initialize()
      .then ->
        eventualConsistencyUtilities.waitForQueryToReturnResult exampleContext, 'getSomething'
      .then (receivedResult) ->
        expect(receivedResult).to.equal queryResult


    it 'should execute the query repeatedly given a query which resolves but not with immediately with a result', ->
      exampleContext = eventric.context 'Example'
      callCount = 0
      exampleContext.addQueryHandlers getSomething: ->
        new Promise (resolve, reject) ->
          callCount++
          if callCount < 5
            resolve null
          else
            resolve {}
      exampleContext.initialize()
      .then ->
        eventualConsistencyUtilities.waitForQueryToReturnResult exampleContext, 'getSomething'
      .then ->
        expect(callCount).to.equal 5


    it 'should reject with a descriptive error given a query which does not yield a result within the timeout', ->
      exampleContext = eventric.context 'Example'
      exampleContext.addQueryHandlers getSomething: ->
        new Promise (resolve) ->
          setTimeout ->
            resolve()
          , 100
      exampleContext.initialize()
      .then ->
        eventualConsistencyUtilities.waitForQueryToReturnResult exampleContext, 'getSomething', {foo: 'bar'}, 50
      .catch (error) ->
        expect(error).to.be.an.instanceof Error
        expect(error.message).to.contain 'Example'
        expect(error.message).to.contain 'getSomething'
        expect(error.message).to.match /"foo"\:\s*"bar"/


  describe '#waitForCommandToResolve', ->

    it 'should call the given command on the given context with the given params', ->
      commandStub = sandbox.stub().returns new Promise (resolve) -> resolve()
      commandParams = {}
      exampleContext = eventric.context 'Example'
      exampleContext.addCommandHandlers DoSomething: commandStub
      exampleContext.initialize()
      .then ->
        eventualConsistencyUtilities.waitForCommandToResolve exampleContext, 'DoSomething', commandParams
      .then ->
        expect(commandStub).to.have.been.calledWith commandParams


    it 'should resolve with the result given a command which resolves with a result', ->
      commandResult = {}
      exampleContext = eventric.context 'Example'
      exampleContext.addCommandHandlers DoSomething: ->
        new Promise (resolve) -> resolve commandResult
      exampleContext.initialize()
      .then ->
        eventualConsistencyUtilities.waitForCommandToResolve exampleContext, 'DoSomething'
      .then (receivedResult) ->
        expect(receivedResult).to.equal commandResult


    it 'should execute the command repeatedly given a command which first rejects and resolves after a while', ->
      exampleContext = eventric.context 'Example'
      callCount = 0
      exampleContext.addCommandHandlers DoSomething: ->
        new Promise (resolve, reject) ->
          callCount++
          if callCount >= 5
            resolve()
          else
            reject()
      exampleContext.initialize()
      .then ->
        eventualConsistencyUtilities.waitForCommandToResolve exampleContext, 'DoSomething'
      .then ->
        expect(callCount).to.equal 5


    it 'should reject with a descriptive error given a command which does not yield a result within the timeout', ->
      exampleContext = eventric.context 'Example'
      exampleContext.addCommandHandlers DoSomething: ->
        new Promise (resolve) ->
          setTimeout ->
            resolve()
          , 100
      exampleContext.initialize()
      .then ->
        eventualConsistencyUtilities.waitForCommandToResolve exampleContext, 'DoSomething', {foo: 'bar'}, 50
      .catch (error) ->
        expect(error).to.be.an.instanceof Error
        expect(error.message).to.contain 'Example'
        expect(error.message).to.contain 'DoSomething'
        expect(error.message).to.match /"foo"\:\s*"bar"/


  describe '#waitForResult', ->

    it 'should call the given promise factory', ->
      promiseFactoryStub = sandbox.stub().returns new Promise (resolve) -> resolve true
      eventualConsistencyUtilities.waitForResult promiseFactoryStub
      .then ->
        expect(promiseFactoryStub).to.have.been.called


    it 'should resolve given a promise resolves with an object', ->
      promiseFactory = -> new Promise (resolve) -> resolve {}
      waitForResult = eventualConsistencyUtilities.waitForResult promiseFactory
      .then ->
        expect(waitForResult).to.be.ok


    it 'should resolve given a promise resolves with true', ->
      promiseFactory = -> new Promise (resolve) -> resolve true
      waitForResult = eventualConsistencyUtilities.waitForResult promiseFactory
      .then ->
        expect(waitForResult).to.be.ok


    it 'should resolve given a promise resolves with false', ->
      promiseFactory = -> new Promise (resolve) -> resolve false
      waitForResult = eventualConsistencyUtilities.waitForResult promiseFactory
      .then ->
        expect(waitForResult).to.be.ok


    it 'should not resolve given a promise returns undefined', ->
      promiseFactory = -> new Promise (resolve) -> resolve undefined
      eventualConsistencyUtilities.waitForResult promiseFactory, 0
      .catch (error) ->
        expect(error).to.be.ok


    it 'should resolve with the result given a promise factory which resolves with a result', ->
      result = {}
      promiseFactory = -> new Promise (resolve) -> resolve result
      eventualConsistencyUtilities.waitForResult promiseFactory
      .then (receivedResult) ->
        expect(receivedResult).to.equal result



    it 'should execute the promise factory repeatedly given it only resolves with a result after a few calls', ->
      callCount = 0
      promiseFactory = ->
        new Promise (resolve, reject) ->
          callCount++
          if callCount >= 3
            resolve {}
          else
            resolve()
      eventualConsistencyUtilities.waitForResult promiseFactory
      .then ->
        expect(callCount).to.equal 3


    it 'should reject with an error given a promise factory which rejects', ->
      error = new Error
      promiseFactory = -> new Promise (resolve, reject) -> reject error
      eventualConsistencyUtilities.waitForResult promiseFactory
      .catch (receviedError) ->
        expect(receviedError).to.equal error


    it 'should reject with an error given a promise factory which does not yield a result within the timeout', ->
      promiseFactory = ->
        new Promise (resolve) ->
          setTimeout ->
            resolve()
          , 100
      eventualConsistencyUtilities.waitForResult promiseFactory, 50
      .catch (error) ->
        expect(error).to.be.an.instanceof Error
