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
      attached: ->
        @fire 'eventsource', @
      eventsChanged: (oldValue, newValue) ->
        events = {}
        for name in (newValue or '').split(' ')
          events[name.trim()]
        @relay = (evt) =>
          console.log 'relay dispatch', evt
          @fire evt.type, evt.detail

