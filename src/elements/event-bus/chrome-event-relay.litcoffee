#Overview
This bridges DOM events into Chrome.

#Attributes
##events
This is a space separated list of event names that will be relayed.
##to
Name of a Chrome event port.

#Methods
##connect
Open up a Chrome port `to` a named connection. This will send along a
`chromeconnect` message via relay as a hello.

    _ = require('lodash')

    Polymer 'chrome-event-relay',
      attached: ->
        @connect()

      connect: ->
        @port = chrome.runtime.connect name: @to
        @relay 'chromeconnect', name: @to

Relay events via Chrome messaging, this lets us go across tabs, background, and
content pages.
And don't relay messages you fired. Inifinite loop buddy!

      relay: () ->
        try
          if arguments.length is 1
            evt = arguments[0]
            message = {}
            message.type = evt.type
            message.detail = evt.detail
            console.log 'chrome relay', message.type, message
            @port.postMessage message
          if arguments.length is 2
            message = {}
            message.type = arguments[0]
            message.detail = arguments[1]
            console.log 'chrome relay', message.type, message
            @port.postMessage message
            @fire arguments[0], arguments[1]
        catch err
          if err.message is "Attempting to use a disconnected port object"
            console.log 'port closed', message

Keep a strict subscription to only the events specified by attribute.

      eventsChanged: (oldValue, newValue) ->
        (oldValue or '').split(' ').forEach (name) =>
          @removeEventListener name.trim(), @relay
        (newValue or '').split(' ').forEach (name) =>
          @addEventListener name.trim(), @relay
