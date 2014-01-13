module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    browserify:
      elements:
        files:[
          {src: '**/*.litcoffee', dest: 'build/bower_components/', expand: true, ext: '.js', cwd: 'src/elements'}
        ]
        options:
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
      tabs:
        files: [
          {src: ['**/*.html'], dest: 'build/', expand: true, cwd: 'src/'}
          {src: ['**/*.svg'], dest: 'build/', expand: true, cwd: 'src/'}
          {src: ['**/*.eot'], dest: 'build/fonts', expand: true, flatten: true, exclude: 'build/'}
          {src: ['**/*.svg'], dest: 'build/fonts', expand: true, flatten: true, exclude: 'build/'}
          {src: ['**/*.ttf'], dest: 'build/fonts', expand: true, flatten: true, exclude: 'build/'}
          {src: ['**/*.woff'], dest: 'build/fonts', expand: true, flatten: true, exclude: 'build/'}
          {src: ['**/*.otf'], dest: 'build/fonts', expand: true, flatten: true, exclude: 'build/'}
          #running the extension from the build directory as the root
          {src: 'manifest.json', dest: 'build/', expand: true, cwd: 'src/'}
        ]
      elements:
        files: [
          #html component definitions, let's just pretend that local ones are
          #bower components
          {src: '**/*.html', dest: 'build/bower_components/', expand: true, cwd: 'src/elements'}
          #actual bower components just copy over, need these to make elements work
          {src: 'bower_components/**', dest: 'build/', expand: true}
        ]
    concat:
      all:
        files: [
          {src: ['src/**/*.*'], dest: 'build/all'}
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

  grunt.registerTask 'build', ['browserify', 'less', 'copy', 'concat']
  grunt.registerTask 'publish', ['build', 'crx']
