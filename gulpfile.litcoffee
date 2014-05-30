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
    hash = require 'gulp-hashmap'
    es = require 'event-stream'

    src ='src'
    dest = 'build'
    gulp.task 'compile js', ->
      gulp.src '**/*.litcoffee', {cwd: src, read: false}
        .pipe browserify
          transform: ['coffeeify', 'browserify-data']
          debug: true
        .pipe rename extname: '.js'
        .pipe gulp.dest dest
    gulp.task 'compile', ['compile js'], ->
      gulp.src '**/*.less', {cwd: src}
        .pipe less()
        .pipe gulp.dest dest
      gulp.src '**/*.html', {cwd: src}
        .pipe gulp.dest dest
      gulp.src '**/*.svg', {cwd: src}
        .pipe gulp.dest dest
      gulp.src '**/*.ogg', {cwd: src}
        .pipe gulp.dest dest

Vulcanize for the speed.

    gulp.task 'vulcanize', ['compile'], ->
      gulp.src ''
        .pipe shell([
          'vulcanize --inline --strip -o build/index.html build/index.html'
          ])
        .pipe shell([
          'vulcanize --inline --strip -o build/screen.html build/screen.html'
          ])

    gulp.task 'devvulcanize', ['compile'], ->
      gulp.src ''
        .pipe shell([
          'vulcanize --inline -o build/index.html build/index.html'
          ])
      gulp.src ''
        .pipe shell([
          'vulcanize --inline -o build/screen.html build/screen.html'
          ])
      gulp.src ''
        .pipe shell([
          'ctags -R src/'
          ])

The main build task.

    gulp.task 'build', ['vulcanize']

Dev task, not the same optimziation on the vulcanize.

    gulp.task 'dev', ['devvulcanize']
