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

All of the semi status stuff, don't bother to rebuild as often

    gulp.task 'assets', ->

Sweep up static assest from all over.

      gulp.src '**/*.*', {cwd: 'src/images'}
        .pipe gulp.dest 'build/images'

      gulp.src '**/*.svg', {cwd: 'src'}
        .pipe flatten()
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

And our custom elements.

    gulp.task 'elements', ['elements-code', 'elements-style', 'elements-static']
    gulp.task  'elements-code', ->
      src ='src/elements'
      dest = 'build/bower_components'
      gulp.src '**/*.litcoffee', {cwd: src, read: false}
        .pipe browserify
          transform: ['coffeeify', 'browserify-data']
          debug: true
        .pipe rename extname: '.js'
        .pipe gulp.dest dest
    gulp.task  'elements-style', ->
      src ='src/elements'
      dest = 'build/bower_components'
      gulp.src '**/*.less', {cwd: src}
        .pipe less()
        .pipe gulp.dest dest
    gulp.task  'elements-static', ->
      src ='src/elements'
      dest = 'build/bower_components'
      gulp.src '**/*.html', {cwd: src}
        .pipe gulp.dest dest
      gulp.src '**/*.svg', {cwd: src}
        .pipe gulp.dest dest

    gulp.task 'pages', ['pages-code', 'pages-style', 'pages-static']
    gulp.task  'pages-code', ->
      src ='src/pages'
      dest = 'build'
      gulp.src '**/*.litcoffee', {cwd: src, read: false}
        .pipe browserify
          transform: ['coffeeify', 'browserify-data']
          debug: true
        .pipe rename extname: '.js'
        .pipe gulp.dest dest
    gulp.task  'pages-style', ->
      src ='src/pages'
      dest = 'build/'
      gulp.src '**/*.less', {cwd: src}
        .pipe less()
        .pipe gulp.dest dest
    gulp.task  'pages-static', ->
      src ='src/pages'
      dest = 'build/'
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

The default task leaves a hash file to support hot reloading.

    gulp.task 'default', ['vulcanize'], ->
      gulp.src 'build/index.html'
        .pipe hash 'hashmap.json'
        .pipe gulp.dest 'build'


    gulp.task 'watch', ['default'], ->
      gulp.watch 'src/**/*.*', ['default']

