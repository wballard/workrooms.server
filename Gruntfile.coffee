module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    browserify:
      build:
        src: ['src/background.coffee']
        dest: 'build/background.js'
        options:
          transform: ['coffeeify', 'node-lessify']
    watch:
      files: ['src/**/*.coffee', 'src/**/*.js', 'src/**/*.less', 'src/**/*.css']
      tasks: ['build']


  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'build', ['browserify']
