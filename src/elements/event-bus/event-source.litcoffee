#Overview
This is the buddy of [event-sink](../event-sink.litcoffee), it repeats events
that make it to the sink so that they can be handled deep in your DOM. This
creates a kind of event broadcasting system that lets you relay events for
elements that might be interested, but were deeper or parallel in the DOM tree.

Put this nice and deep in your DOM so that events that would otherwise
be above or beside you can be caught. And make sure the overall DOM is
surrounded by at least one `event-sink`, otherwise this just isn't
going to do anything.

#Attributes
##events
This is a space separated list of event names that will be relayed. Other
events will be ignored.

#Events
##eventsourceattached
This event is fired to bubble up to any containing
[event-sink](../event-sink.litcoffee) in order to register this element to
receive relayed events.

    _ = require('lodash')

    Polymer 'event-source',
      relay: ->
      attached: ->
        console.log 'attach source', @events
        @wireEvents @events
        @fire 'eventsourceattached', @

This does the connection of events based on the space separated string
of event names.

      wireEvents: (eventstring) ->
        events = {}
        (eventstring or '').split(' ').forEach (name) ->
          events[name.trim()] = true
        @relay = (evt) =>
          console.log 'SOURCE?', evt.type, evt.detail, _.keys(events)
          if events[evt.type]
            console.log 'SOURCE', evt.type, evt.detail
            @fire evt.type, evt.detail
      eventsChanged: (oldValue, newValue) ->
        @wireEvents(newValue)
