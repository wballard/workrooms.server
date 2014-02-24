Watching building with gulp, this is the client side package
so there is no problem with `npm start` blocking, it just is rigged to run this
build script and watch for changes.

    gulp = require 'gulp'
    less = require 'gulp-less'
    browserify = require 'gulp-browserify'
    rename = require 'gulp-rename'
    flatten = require 'gulp-flatten'
    watch = require 'gulp-watch'
    concat = require 'gulp-continuous-concat'
    plumber = require 'gulp-plumber'

    gulp.task 'default', ->

The chrome app manifest has no transforms.

      gulp.src 'manifest.json', {cwd: 'src'}
        .pipe gulp.dest 'build'

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

Map source directories to target build directories, then run the pipelines
for each.

      targets =
        'src/elements': 'build/bower_components'
        'src/tabs': 'build/tabs'
        'src/pages': 'build/pages'

Each area has html templates, less styles, and litcoffee source.

      for src, dest of targets
        gulp.src '**/*.litcoffee', {cwd: src, read: false}
          .pipe watch {read: false}
          .pipe browserify
            transform: ['coffeeify', 'browserify-data']
            debug: true
          .pipe rename extname: '.js'
          .pipe gulp.dest dest
          .pipe concat('all')
        gulp.src '**/*.less', {cwd: src}
          .pipe watch()
          .pipe less()
          .pipe gulp.dest dest
        gulp.src '**/*.html', {cwd: src}
          .pipe watch()
          .pipe gulp.dest dest
        gulp.src '**/*.svg', {cwd: src}
          .pipe watch()
          .pipe gulp.dest dest

Drive the hot reload.

      gulp.src 'src/**'
        .pipe watch(emit: 'all')
        .pipe plumber()
        .pipe concat('all')
        .pipe gulp.dest 'build'

