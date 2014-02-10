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

    Polymer 'chrome-tab-event-relay',

Relay events via Chrome messaging, to all tabs.
And don't relay messages you fired. Inifinite loop buddy!

      relay: (evt) ->
        message = {}
        message.type = evt.type
        message.detail = evt.detail
        console.log 'chrome tab relay', message, evt?.detail
        chrome.tabs.query active: true, (tabs) ->
          chrome.tabs.sendMessage tabs[0].id, message

Keep a strict subscription to only the events specified by attribute.

      eventsChanged: (oldValue, newValue) ->
        console.log 'attach chrome tab', @events
        (oldValue or '').split(' ').forEach (name) =>
          @removeEventListener name.trim(), @relay
        (newValue or '').split(' ').forEach (name) =>
          @addEventListener name.trim(), @relay
