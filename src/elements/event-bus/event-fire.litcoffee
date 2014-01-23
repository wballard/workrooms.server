#Overview
This fires off named events when it is placed in the DOM. You use
it to bootstrap an event driven page declaratively.


#Attributes
##events
This is a space separated list of event names to fire.

    Polymer 'event-fire',
      eventsChanged: (oldValue, newValue) ->
        (newValue or '').split(' ').forEach (name) =>
          console.log 'fireball', name
          @fire name
