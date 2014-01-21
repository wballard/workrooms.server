Use an `event-sink` to wrap around DOM elements and relay events
back to `event-source` elements. This lets you bubble events 'up' the
DOM and have them restart down deep in the DOM again.

Think about a toolbar, near the root of your DOM, that needs to send a message
to an element deep in the DOM, but not nested in the toolbar. This component
lets you, for example, wrap an entire page right inside body and then relay
events to all `event-source`. Like rebubbling events.

#Attributes
##events
This is a space separated list of event names that will be relayed.

    Polymer 'event-sink',
      sources: []
      attached: ->
        @addEventListener 'eventsource', (evt) ->
          @sources.push(evt.detail)

Relay events. The most important rule here is to not relay events that
themselves were relayed already, which can be detected by looking if they
came from an `event-source`.

      relay: (evt) ->
        if evt.srcElement.nodeName isnt "EVENT-SOURCE"
          console.log 'relay!', evt
          @sources.forEach (source) ->
            source.relay(evt)
      eventsChanged: (oldValue, newValue) ->
        for name in (oldValue or '').split(' ')
          @removeEventListener name.trim(), @relay
        for name in (newValue or '').split(' ')
          @addEventListener name.trim(), @relay
