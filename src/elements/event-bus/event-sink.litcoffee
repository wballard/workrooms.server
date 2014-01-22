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

    Polymer 'event-sink',
      sources: []
      attached: ->
        @addEventListener 'eventsourceattached', (evt) ->
          @sources.push(evt.detail)
        @addEventListener 'eventsourcedetached', (evt) ->
          @sources = _.remove(@sources, evt.detail)

Relay events. The most important rule here is to not relay events that
themselves were relayed already, which can be detected by looking if they
came from an `event-source`.

      relay: (evt) ->
        if evt?.srcElement?.nodeName isnt "EVENT-SOURCE"
          @sources.forEach (source) ->
            source.relay(evt)

If we are in a chrome app, relay the message to Chrome as well, this lets
us go across tabs, background, and content pages.

And, some messages just can't be relayed or serialized out of process, like
a WebSocket itself, or a MediaStream.

          if chrome?.runtime?.sendMessage and not evt?.detail?.__not_serializable__
            message = {}
            message[evt.type] = true
            message.detail = evt.detail
            chrome.runtime.sendMessage message

Keep a strict subscription to only the events specified by attribute.

      eventsChanged: (oldValue, newValue) ->
        (oldValue or '').split(' ').forEach (name) =>
          @removeEventListener name.trim(), @relay
        (newValue or '').split(' ').forEach (name) =>
          @addEventListener name.trim(), @relay

      autofireChanged: (oldValue, newValue) ->
        (newValue or '').split(' ').forEach (name) =>
          @relay
            type: name
