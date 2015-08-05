mocha       = require 'gulp-mocha'
runSequence = require 'run-sequence'

# TODO: Add client spec run
module.exports = (gulp) ->

  gulp.task 'specs', (next) ->
    runSequence 'specs:server', next


  gulp.task 'specs:server', ->
    gulp.src([
      'src/spec_setup.coffee'
      'src/*.spec.coffee'
    ])
    .pipe mocha(reporter: 'spec')
