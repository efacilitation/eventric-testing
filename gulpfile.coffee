gulp  = require 'gulp'
gutil = require 'gulp-util'

gulp.on 'err', (error) ->
gulp.on 'task_err', (error) ->
  if process.env.CI
    gutil.log error
    process.exit 1

require('./gulp/build')(gulp)
require('./gulp/specs')(gulp)
require('./gulp/watch')(gulp)