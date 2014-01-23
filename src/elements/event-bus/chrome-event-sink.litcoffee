#Overview
This event sink takes DOM events and relays them along to the Chrome extension
message system, alloing you to share across tabs and pages.

#Attributes
##events
This is a space separated list of event names that will be relayed.
##autofire
This is a space separated list of event names to fire automatically.

    _ = require('lodash')
    uuid = require('node-uuid')

    Polymer 'chrome-event-sink',
      sessionid: uuid.v1()
      attached: ->
        console.log 'attach chrome', @events
        chrome.runtime.onMessage.addListener (message, sender, respond) =>
          if message.type and message.from isnt @sessionid
            console.log 'chrome bubble', message
            @fire message.type, message.detail

Relay events via Chrome messaging, this lets us go across tabs, background, and
content pages.
And don't relay messages you fired. Inifinite loop buddy!

      relay: (evt) ->
        if chrome.runtime.sendMessage and evt.target isnt @
          message = {}
          message.type = evt.type
          message.detail = evt.detail
          message.from = @sessionid
          console.log 'chrome relay', message
          chrome.runtime.sendMessage message

Keep a strict subscription to only the events specified by attribute.

      eventsChanged: (oldValue, newValue) ->
        (oldValue or '').split(' ').forEach (name) =>
          @removeEventListener name.trim(), @relay
        (newValue or '').split(' ').forEach (name) =>
          @addEventListener name.trim(), @relay
