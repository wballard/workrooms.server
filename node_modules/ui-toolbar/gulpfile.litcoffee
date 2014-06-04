Build ui-toolbar from source into
build/ui-toolbar.html, all streamlined and ready to be included.

Having both the literate source, and the fully built output allows you to choose
if you want to have a fully `vulcanize` input, or to fully `vulcanize` your
entire project at the end.

    gulp = require 'gulp'
    less = require 'gulp-less'
    browserify = require 'gulp-browserify'
    rename = require 'gulp-rename'
    shell = require 'gulp-shell'
    replace = require 'gulp-replace'
    concat = require 'gulp-concat'
    express = require 'express'
    util = require 'util'
    livereload = require 'express-livereload'
    handle = (stream)->
      stream.on 'error', ->
        util.log.apply this, arguments
        stream.end()
    src ='./src'
    dest = 'build/'

And our custom elements.

    gulp.task 'elements', ['elements-code', 'elements-style', 'elements-static']
    gulp.task  'elements-code', ->
      gulp.src '*.litcoffee', {cwd: src, read: false}
        .pipe handle browserify
          transform: ['coffeeify', 'browserify-data']
          debug: false
        .pipe rename extname: '.js'
        .pipe gulp.dest dest
    gulp.task  'elements-style', ->
      gulp.src '*.less', {cwd: src}
        .pipe handle less()
        .pipe gulp.dest dest
    gulp.task  'elements-static', ->
      gulp.src '*.html', {cwd: src}
        .pipe gulp.dest dest
      gulp.src '*.svg', {cwd: src}
        .pipe gulp.dest dest

Make up a readme based on literate programming of the element.

    gulp.task 'readme', ->
      gulp.src '*.litcoffee', {cwd: src}
        .pipe replace /^\s\s\s\s.*$/gm, ''
        .pipe concat 'README.md'
        .pipe gulp.dest '.'


Vulcanize for the speed.

    gulp.task 'vulcanize', ['elements'], ->
      built = 'build/ui-toolbar.html'
      gulp.src '*.html', {cwd: dest}
        .pipe shell([
          "vulcanize --inline --strip -o <%= file.path %> <%= file.path %>"
          ])

    gulp.task 'build', ['vulcanize', 'readme']

    gulp.task 'watch', ->
      app = express()
      app.use(express.static(__dirname))
      livereload app,
        port: 35729
        watchDir: __dirname
      app.listen(10000)
      console.log 'http://localhost:10000/demo.html'

      watcher = gulp.watch 'src/**/*.*', ['elements', 'readme']
      watcher.on 'change', ->
        console.log 'rebuildling...'
