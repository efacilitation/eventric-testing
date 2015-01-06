module.exports = (gulp) ->
  gulp.task 'watch', ->
    gulp.watch [
      'src/*.coffee'
    ], [
      'build'
      'spec'
    ]
