#Overview
This gets events from Chrome and turns them into DOM events.

#Attributes
##name
Named message channel.

    _ = require('lodash')
    uuid = require('node-uuid')

    Polymer 'chrome-event-source',
      attached: ->
        chrome.runtime.onMessage.addListener (message) =>
          if message.name is @name
            console.log 'chrome bubble', message.type, message
            @fire message.type, message.detail

