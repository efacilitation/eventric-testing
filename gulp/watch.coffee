runSequence = require 'run-sequence'

module.exports = (gulp) ->
  gulp.task 'watch', ->
    gulp.watch 'src/*.coffee', ['specs']
