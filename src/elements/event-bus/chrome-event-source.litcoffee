#Overview
This gets events from Chrome and turns them into DOM events.

#Attributes
##name
Name of a Chrome event port.

    _ = require('lodash')
    uuid = require('node-uuid')

    Polymer 'chrome-event-source',
      attached: ->
        chrome.runtime.onConnect.addListener (port) =>
          if port.name is @name
            console.log 'chrome listening', @name

Listen for and re-bubble events unless they can from here or are tab targeted.

            port.onMessage.addListener (message, sender, respond) =>
              if message.type
                console.log 'chrome bubble', message.type, message
                @fire message.type, message.detail

