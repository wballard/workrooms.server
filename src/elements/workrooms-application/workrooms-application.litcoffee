This is the main application code. A bit different setup, using a custom
element as the application root, comparing this to using Angular.js it
seems like a good idea since there is just one 'scope tree' this way, the
DOM itself! And, just one event space, the DOM itself -- no need for the
separate event mechanisms of `$emit` and `$broadcast`.

Store configurations for each runtime id along with the code.

    config = require('../../config.yaml')
    config = config[chrome.runtime.id] or config['default']

    Polymer 'workrooms-application',

This is the magic part, set config and watch the data binding fill in the
elements that actually do work!

      ready: ->
        console.log 'application starting', config
        @config = config

      attached: ->

        @addEventListener 'configured', (evt) =>
          @serverConfig = evt.detail
          @$.github.login()

Ask for configuration when the server says hello. This fires off github since
an event fired off the server itself would refuse to relay.

        @addEventListener 'hello', =>
          @$.github.fire 'register',
            runtime: chrome.runtime.id

