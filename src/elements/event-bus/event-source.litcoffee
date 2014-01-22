This is the buddy of `event-sink`, it repeats events that make it to
the sink so that they can be handled deep in your DOM.

Put this nice and deep in your DOM so that events that would otherwise
be above or beside you can be caught. And make sure the overall DOM is
surrounded by at least one `event-sink`, otherwise this just isn't
going to do anything.

#Attributes
##events
This is a space separated list of event names that will be fired.

#Events
##eventsource
This event is fired to bubble up to any containing `event-sink` in order
to register that this `event-source` exists and needs events relayed.

    _ = require('lodash')

    Polymer 'event-source',
      relay: ->
      chromeRelay: ->
      attached: ->
        console.log 'attach source', @events
        @wireEvents @events
        @fire 'eventsource', @
        if chrome?.runtime?.onMessage
          chrome.runtime.onMessage.addListener (message, sender, respond) =>
            @chromeRelay message

This does the connection of events based on the space separated string
of event names.

      wireEvents: (eventstring) ->
        events = {}
        (eventstring or '').split(' ').forEach (name) ->
          console.log 'source', name
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

