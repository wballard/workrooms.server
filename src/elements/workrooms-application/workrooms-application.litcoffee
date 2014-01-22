This is the main application code. A bit different setup, using a custom
element as the application root, comparing this to using Angular.js it
seems like a good idea since there is just one 'scope tree' this way, the
DOM itself! And, just one event space, the DOM itself -- no need for the
separate event mechanisms of `$emit` and `$broadcast`.

Store configurations for each runtime id along with the code.

    config = require('../../config.yaml')?[chrome.runtime.id]

    Polymer 'workrooms-application',

This is the magic part, set config and watch the data binding fill in the
elements that actually do work!

      ready: ->
        console.log 'application starting', config
        @config = config
