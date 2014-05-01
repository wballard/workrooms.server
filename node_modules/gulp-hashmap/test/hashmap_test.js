"use strict";
var hash = require("../index.js"),
    gulp = require("gulp"),
    through = require("through2"),
    path = require("path");

describe("gulp-hashmap", function() {
  it("it creates a hashmap, passing through files", function(done) {
    var files = [];

    var stream = through.obj(function(file, enc, done) {
      files.push(file);
      done();
    }, function() {
      files.length.should.equal(4);
      files.forEach(function(val, idx) {
        if (path.basename(val.path) === "map.json") {
          var json = JSON.parse(val.contents.toString());
          json.should.have.keys("gulpfile.js", "index.js", "test/hashmap_test.js");
          json["gulpfile.js"].should.match(/^[a-f0-9]{40}$/);
          done();
        }
      });
    });

    gulp.src([__dirname+"/../*.js", __dirname+"/*.js"])
      .pipe(hash({target: "map.json", flatten: false}))
      .pipe(stream)
  });
});
