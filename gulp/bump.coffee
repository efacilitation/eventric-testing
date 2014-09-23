bump = require 'gulp-bump'

module.exports = (gulp) ->
  filesToBump = './+(bower|package).json'

  gulp.task 'bump:minor', ->
    gulp.src filesToBump
    .pipe bump(type: 'minor')
    .pipe gulp.dest('./')

  gulp.task 'bump:patch', ->
    gulp.src filesToBump
    .pipe bump(type: 'patch')
    .pipe gulp.dest('./')
