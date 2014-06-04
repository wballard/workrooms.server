#What's This
[Polymer](http://www.polymer-project.org/) is fantastic, but needing two
package managers for everything I do -- `npm` and `bower` doesn't really
add great value when you are using [browserify](http://browserify.org/).

#Get Started
Yep -- it's a node module.

```shell
npm install --save Custom-Elements/polymer
```

And, into your app, assuming you have a `./index.html` and can serve the
contents of `./node_modules` with something like
[serve-static](https://github.com/expressjs/serve-static):

```html
<!DOCTYPE html>
<html>
<head>
<!-- 1. Load platform.js for polyfill support. -->
<script src="node_modules/platform.js"></script>
<!-- 2. Use an HTML Import to bring in polymer. -->
<link rel="import" href="node_modules/polymer/polymer.html">
</head>
</html>
```
