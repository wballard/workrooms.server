#Overview
This event sink takes DOM events and relays them along to the Chrome extension
message system, alloing you to share across tabs and pages.

#Attributes
##sendevents
This is a space separated list of event names that will be relayed and sent
along if detected from Chrome.
##listenevents
This is a space separated list of event names that will be bubbled if heard
from Chrome.

    _ = require('lodash')
    uuid = require('node-uuid')

    Polymer 'chrome-tab-event-relay',
      bubble: {}
      attached: ->
        chrome.runtime.onMessage.addListener (message, sender, respond) =>
          if @bubble[message.type]
            @fire message.type, message.detail

Relay events via Chrome messaging, to all tabs.
And don't relay messages you fired. Inifinite loop buddy!

      relay: (evt) ->
        message = {}
        message.type = evt.type
        message.detail = evt.detail
        chrome.tabs.query {}, (tabs) ->
          tabs.forEach (tab) ->
            console.log 'chrome tab relay', message, evt?.detail, tab.id
            chrome.tabs.sendMessage tab.id, message

Keep a strict subscription to only the events specified by attribute.

      sendeventsChanged: (oldValue, newValue) ->
        console.log 'attach chrome tab send', @sendevents
        (oldValue or '').split(' ').forEach (name) =>
          @removeEventListener name.trim(), @relay
        (newValue or '').split(' ').forEach (name) =>
          @addEventListener name.trim(), @relay

      listeneventsChanged: (oldValue, newValue) ->
        console.log 'attach chrome tab listen', @listenevents
        @bubble = {}
        newValue.split(' ').forEach (name) =>
          @bubble[name] = true

