module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    browserify:
      background:
        expand: true
        src: ['src/*.coffee']
        dest: 'build/'
        ext: '.js'
        flatten: true
        options:
          transform: ['coffeeify', 'node-lessify']
      conference:
        src: ['src/conference.coffee']
        dest: 'build/conference.js'
        options:
          transform: ['coffeeify', 'node-lessify']
    copy:
      tabs:
        files: [
          {src: ['**/*.html'], dest: 'build/', expand: true, cwd: 'src/'}
        ]
    watch:
      files: ['src/**/*.coffee', 'src/**/*.js', 'src/**/*.less', 'src/**/*.css', 'src/**/*.html']
      tasks: ['build']


  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  grunt.registerTask 'build', ['browserify', 'copy']
