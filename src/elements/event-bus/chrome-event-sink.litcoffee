#Overview
Use an `event-sink` to wrap around DOM elements and relay events
back to `event-source` elements. This lets you bubble events up the
DOM and have them restart down deep in the DOM again.

Think about a toolbar, near the root of your DOM, that needs to send a message
to an element deep in the DOM, but not nested in the toolbar. This component
lets you, for example, wrap an entire page right inside `<body>` and then relay
events to all `event-source`.

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
        console.log 'attach chrome sink', @events
        chrome.runtime.onMessage.addListener (message, sender, respond) =>
          if message.type and message.from isnt @sessionid
            console.log 'chrome bubble', message
            @fire message.type, message.detail

Relay events via Chrome messaging, this lets us go across tabs, background, and
content pages. The most important rule here is to not relay events that
themselves were relayed already, which can be detected by looking if they came
from an [event-source](../event-source.litcoffee).

      relay: (evt) ->
        if evt?.srcElement?.nodeName isnt "EVENT-SOURCE"
          if chrome.runtime.sendMessage
            message = {}
            message.type = evt.type
            message.detail = evt.detail
            message.from = @sessionid
            console.log 'chrome relay', message
            chrome.runtime.sendMessage message

Keep a strict subscription to only the events specified by attribute.

      eventsChanged: (oldValue, newValue) ->
        console.log 'listen chrome sink', @events
        (oldValue or '').split(' ').forEach (name) =>
          @removeEventListener name.trim(), @relay
        (newValue or '').split(' ').forEach (name) =>
          @addEventListener name.trim(), @relay
