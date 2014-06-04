Build font files into css importable snippets, one per font.

    gulp = require 'gulp'
    rename = require 'gulp-rename'
    es = require 'event-stream'
    fs = require 'fs'
    handlebars = require 'handlebars'
    path = require 'path'
    util = require 'util'
    handle = (stream)->
      stream.on 'error', ->
        util.log.apply this, arguments
        stream.end()

Load up all the fonts to be used as substitution variables.

    fonts = {}
    gulp.task 'fonts', ->
      gulp.src '*.woff', {cwd: 'fonts'}
        .pipe handle do ->
          es.map (file, callback) ->
            fs.readFile file.path, (err, data) ->
              fonts[path.basename(file.path, '.woff')] = file.contents.toString('base64')
              callback undefined, file

    gulp.task 'build', ['fonts'], ->
      gulp.src '*.less', {cwd: 'src'}
        .pipe handle do ->
          es.map (file, callback) ->
            template = handlebars.compile(file.contents.toString('utf8'))
            file.contents = new Buffer(template(fonts))
            callback undefined, file
        .pipe gulp.dest('build')
        .pipe rename extname: '.css'
        .pipe gulp.dest('build')

    gulp.task 'watch',  ['build'], ->
      watcher = gulp.watch 'src/**/*.*', ['build']
      watcher.on 'change', ->
        console.log 'rebuildling...'
