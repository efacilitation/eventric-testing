mocha       = require 'gulp-mocha'
runSequence = require 'run-sequence'

# TODO: Add client spec run
module.exports = (gulp) ->
  gulp.task 'spec', (next) =>
    runSequence 'spec:server', ->
      next()


  gulp.task 'spec:server', =>
    gulp.src([
      'src/spec_setup.coffee'
      'src/*.spec.coffee'
      ])
      .pipe mocha(reporter: 'spec')
