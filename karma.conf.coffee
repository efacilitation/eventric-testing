# Karma configuration

module.exports = (config) ->
  config.set
    # base path, that will be used to resolve files and exclude
    basePath: ''

    # list of files / patterns to load in the browser
    files: [
      # commonjs require
      'node_modules/commonjs-require/commonjs-require.js'

      # spec helper
      'build/spec/helper.js'

      # source
      'src/fake_promise.coffee'

      # specs
      'src/spec_setup.coffee'
      'src/fake_promise.spec.coffee'
    ]

    # list of files to exclude
    exclude: [

    ]

    # compile coffee scripts and wrap into commonjs
    preprocessors:
      'src/fake_promise.coffee': ['commonjs', 'coffee']
      'src/spec_setup.coffee': ['coffee']
      'src/fake_promise.spec.coffee': ['coffee']

    coffeePreprocessor:
      options:
        sourceMap: true

    commonjsPreprocessor:
      options:
        pathReplace: (path) ->
          path

    # web server port
    port: 9876

    # enable / disable colors in the output (reporters and logs)
    colors: yes

    # level of logging
    # possible values: LOG_DISABLE || LOG_ERROR || LOG_WARN || LOG_INFO || LOG_DEBUG
    logLevel: config.LOG_DEBUG

    # enable / disable watching file and executing tests whenever any file changes
    autoWatch: no

    # Start these browsers, currently available:
    # - Chrome
    # - ChromeCanary
    # - Firefox
    # - Opera
    # - Safari
    # - PhantomJS
    browsers: ['PhantomJS']

    # Continuous Integration mode
    # if true, it capture browsers, run tests and exit
    singleRun: yes

    reporters: ['spec']

    frameworks: ['mocha']

    plugins: [
      'karma-mocha'
      'karma-phantomjs-launcher'
      'karma-spec-reporter'
      'karma-coffee-preprocessor'
      'karma-commonjs-preprocessor'
    ]
