# gulp-hashmap

Create a JSON map of file hashes, passing all files through.

## Usage
```javascript
var hash = require("gulp-hashmap"),
    uglify = require("gulp-uglify");

// Uglify scripts, create a hashmap and write all to the dist directory
grunt.task("build", function() {
  grunt.src("scripts/*.js")
    .pipe(uglify())
    .pipe(hash("hashmap.json"))
    .pipe(grunt.dest("dist/"));
});
```

## License
MIT
