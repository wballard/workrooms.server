#Overview
This is the buddy of `event-sink`, it repeats events that make it to
the sink so that they can be handled deep in your DOM. This creates a kind
of event broadcasting system that lets you repeat events for elements that
might be interested, but were deeper or parallel in the DOM tree.

Put this nice and deep in your DOM so that events that would otherwise
be above or beside you can be caught. And make sure the overall DOM is
surrounded by at least one `event-sink`, otherwise this just isn't
going to do anything.

#Attributes
##events
This is a space separated list of event names that will be fired. Other
events will be ignored.

#Events
##eventsourceattached
This event is fired to bubble up to any containing `event-sink` in order
to register that this `event-source` exists and needs events relayed.
#eventsourcedetached
This is fired when this element is going away and needs to not receive any
more event relays. Just for cleanup.

    _ = require('lodash')

    Polymer 'event-source',
      relay: ->
      chromeRelay: ->
      attached: ->
        console.log 'attach source', @events
        @wireEvents @events
        @fire 'eventsourceattached', @
        if chrome?.runtime?.onMessage
          chrome.runtime.onMessage.addListener (message, sender, respond) =>
            @chromeRelay message
      detached: ->
        console.log 'detach source', @events
        @fire 'eventsourcedetached', @

This does the connection of events based on the space separated string
of event names.

      wireEvents: (eventstring) ->
        events = {}
        (eventstring or '').split(' ').forEach (name) ->
          events[name.trim()] = true
        @relay = (evt) =>
          if events[evt.type]
            console.log 'relay dispatch', evt.type, evt.detail
            @fire evt.type, evt.detail
        @chromeRelay = (message) =>
          _.keys(events).forEach (type) =>
            if message[type]
              console.log 'chrome relay dispatch', type, message.detail
              @fire type, message.detail
              return
      eventsChanged: (oldValue, newValue) ->
        @wireEvents(newValue)

