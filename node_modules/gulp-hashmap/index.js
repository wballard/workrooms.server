"use strict";
var crypto = require("crypto"),
    through = require("through2"),
    path = require("path"),
    File = require("gulp-util").File;

var map = {};

module.exports = function(opts) {
  opts = typeof(opts) === "string" ? {target: opts} : (opts || {});
  opts.target = opts.target || "assets.json";
  opts.algorithm = opts.algorithm || "sha1";
  opts.length = opts.length || null;
  opts.flatten = opts.flatten === false ? opts.flatten : true;
  opts.cwd = opts.cwd || process.cwd();

  if (!map.hasOwnProperty(opts.target)) {
    map[opts.target] = {};
  }

  var stream = through.obj(function(file, enc, done) {
    this.push(file);

    if (file.isNull()) return;

    var contents = file.isBuffer() ? file.contents : new Buffer();
    if (file.isStream()) file.contents.pipe(contents);

    var digest = crypto.createHash(opts.algorithm);
    digest.update(file.contents);
    var tag = digest.digest("hex");

    var name = opts.flatten ? path.basename(file.path) : path.relative(opts.cwd, file.path);
    map[opts.target][name] = opts.length ? tag.substr(0, opts.length) : tag;

    done();
  }, function(done) {
    var file = new File({
      cwd: opts.cwd,
      base: opts.cwd,
      path: path.join(opts.cwd, opts.target),
      contents: new Buffer(JSON.stringify(map[opts.target]))
    });

    this.push(file);
    done();
  });

  return stream;
};
