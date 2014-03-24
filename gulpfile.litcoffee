Watching building with gulp, this is the client side package
so there is no problem with `npm start` blocking, it just is rigged to run this
build script and watch for changes.

    gulp = require 'gulp'
    less = require 'gulp-less'
    browserify = require 'gulp-browserify'
    rename = require 'gulp-rename'
    flatten = require 'gulp-flatten'
    concat = require 'gulp-concat'
    plumber = require 'gulp-plumber'
    shell = require 'gulp-shell'

All of the semi status stuff, don't bother to rebuild as often

    gulp.task 'assets', ->

Sweep up static assest from all over.

      gulp.src '**/*.*', {cwd: 'src/images'}
        .pipe gulp.dest 'build/images'

      gulp.src '**/images/*.*', {cwd: 'bower_components'}
        .pipe flatten()
        .pipe gulp.dest 'build/bower_components/images'

      gulp.src '**/fonts/*.*', {cwd: 'bower_components'}
        .pipe flatten()
        .pipe gulp.dest 'build/fonts'
        .pipe gulp.dest 'build/bower_components/fonts'

      gulp.src '**', {cwd: 'bower_components'}
        .pipe gulp.dest 'build/bower_components/'

And our scripts

    gulp.task 'elements', ->
      compile 'src/elements', 'build/bower_components'
    gulp.task 'pages', ->
      compile 'src/pages', 'build/'

Each area has html templates, less styles, and litcoffee source.

    compile = (src, dest) ->
      console.log 'compiling', src
      gulp.src '**/*.litcoffee', {cwd: src, read: false}
        .pipe browserify
          transform: ['coffeeify', 'browserify-data']
          debug: true
        .pipe rename extname: '.js'
        .pipe gulp.dest dest
      gulp.src '**/*.less', {cwd: src}
        .pipe less()
        .pipe gulp.dest dest
      gulp.src '**/*.html', {cwd: src}
        .pipe gulp.dest dest
      gulp.src '**/*.svg', {cwd: src}
        .pipe gulp.dest dest

Vulcanize for the speed.

    gulp.task 'vulcanize', ['elements', 'pages', 'assets'], ->
      gulp.src ''
        .pipe shell([
          'vulcanize --inline --strip -o build/index.html build/index.html'
        ])

    gulp.task 'default', ['all']
    gulp.task 'all', ['vulcanize', 'assets']
    gulp.task 'watch', ['elements', 'pages'], ->
      gulp.watch 'src/**/*.*', ['elements', 'pages']
