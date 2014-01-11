module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    browserify:
      build:
        expand: true
        files:
          './build/background.js': './src/background.coffee'
          './build/tabs/conference.js': './src/conference.coffee'
          './build/gravatars.js': './src/gravatars.coffee'
        options:
          transform: ['coffeeify', 'node-lessify']
          shim:
            MutationSummary:
              path: './vendor/mutation-summary.js'
              exports: 'MutationSummary'
            PathObserver:
              path: './vendor/observe.js'
              exports: 'PathObserver'
            'polyfill-webcomponents':
              path: './vendor/platform.js'
              exports: null
    less:
      build:
        files:
          './build/gravatars.css': './src/less/gravatars.less'
          './build/main.css': './src/less/main.less'
    copy:
      tabs:
        files: [
          {src: ['**/*.html'], dest: 'build/', expand: true, cwd: 'src/'},
          {src: ['**/*.svg'], dest: 'build/', expand: true, cwd: 'src/'}
          {src: 'manifest.json', dest: 'build/', expand: true, cwd: 'src/'}
        ]
    watch:
      files: ['src/**/*.coffee', 'src/**/*.js', 'src/**/*.less', 'src/**/*.css', 'src/**/*.html', 'src/**/*.svg', 'src/**/*.json']
      tasks: ['build']


  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-less'

  grunt.registerTask 'build', ['browserify', 'less', 'copy']
  grunt.registerTask 'publish', ['build', 'crx']
