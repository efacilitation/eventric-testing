webpack = require 'webpack-stream'

module.exports = (gulp) ->

  gulp.task 'build', (next) ->
    webpackConfig = require('./webpack_config').getDefaultConfiguration()
    webpackConfig.output =
      libraryTarget: 'umd'
      library: 'eventric-testing'
      filename: 'eventric_testing.js'

    gulp.src ['src/index.coffee']
    .pipe webpack webpackConfig
    .pipe gulp.dest 'dist/release'
