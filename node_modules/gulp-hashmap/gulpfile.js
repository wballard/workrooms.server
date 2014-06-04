"use strict";
var gulp = require("gulp"),
    jshint = require("gulp-jshint");

gulp.task("default", function() {
  gulp.src(["*.js", "test/*.js"])
    .pipe(jshint())
    .pipe(jshint.reporter());
});
