module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    browserify:
      elements:
        files:[
          {src: '**/*.litcoffee', dest: 'build/bower_components/', expand: true, ext: '.js', cwd: 'src/elements'}
        ]
        options:
          debug: true
          transform: ['coffeeify', 'browserify-data']
          shim:
            MutationSummary:
              path: './vendor/mutation-summary.js'
              exports: 'MutationSummary'
            PathObserver:
              path: './vendor/observe.js'
              exports: 'PathObserver'
    less:
      elements:
        files: [
          {src: '**/*.less', dest: 'build/bower_components/', expand: true, ext: '.css', cwd: 'src/elements'}
        ]
      tabs:
        files: [
          {src: '**/*.less', dest: 'build/tabs/', expand: true, ext: '.css', cwd: 'src/tabs'}
        ]
    copy:
      extension:
        files: [
          #running the extension from the build directory as the root
          {src: 'manifest.json', dest: 'build/', expand: true, cwd: 'src/'}
          {src: '**/*.*', dest: 'build/images', expand: true, cwd: 'src/images'}
        ]
      tabs:
        files: [
          {src: ['tabs/**/*.html'], dest: 'build/', expand: true, cwd: 'src/'}
        ]
      pages:
        files: [
          {src: ['pages/**/*.html'], dest: 'build/', expand: true, cwd: 'src/'}
        ]
      fonts:
        files: [
          {src: ['**/*.eot'], dest: 'build/fonts', expand: true, flatten: true, exclude: 'build/'}
        ]
      elements:
        files: [
          #html component definitions, let's just pretend that local ones are
          #bower components
          {src: '**/*.html', dest: 'build/bower_components/', expand: true, cwd: 'src/elements'}
          {src: '**/*.svg', dest: 'build/bower_components/', expand: true, cwd: 'src/elements'}
          #actual bower components just copy over, need these to make elements work
          {src: 'bower_components/**', dest: 'build/', expand: true}
        ]
    concat:
      all:
        files: [
          {src: ['src/**/*.*'], dest: 'build/all', exclude: 'src/images/**/*.*'}
        ]
    concurrent:
      things: ['browserify', 'less', 'copy']
    compress:
      release:
        options:
          archive: 'release/workrooms.zip'
        files: [
          {src: ['**'], dest: '/', expand: true, cwd: 'build'}
        ]
    watch:
      files: [
        'Gruntfile.coffee',
        'src/**/*.coffee',
        'src/**/*.litcoffee',
        'src/**/*.js',
        'src/**/*.less',
        'src/**/*.css',
        'src/**/*.html',
        'src/**/*.svg',
        'src/**/*.json'
      ]
      tasks: ['build']


  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-concurrent'
  grunt.loadNpmTasks 'grunt-contrib-compress'

  grunt.registerTask 'build', ['concurrent:things', 'concat']
  grunt.registerTask 'release', ['build', 'compress']
