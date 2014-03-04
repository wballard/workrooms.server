The conference room is a lot like a controller, bringing together
multiple different elements and coordinating them. In particular, this
element is responsible for taking events from `RTCPeerConnection` objects in
scope and sending them along to the signalling server in order to set up
peer-to-peer communication.

This differs from a controller in that only the DOM scoping is used, events
bubble up from contained elements, and messages are send back down
via method calls and property sets. Nice and simple.

#Attributes
##localstream
This is your local video/audio data stream.
##calls
Array of all active calls metadata. These aren't calls themselves, just
identifiers used to data bind and generate `ui-video-call` elements.
##userprofiles
All the known profiles for the current user.

    require('../elementmixin.litcoffee')
    uuid = require('node-uuid')
    _ = require('lodash')
    qwery = require('qwery')
    bonzo = require('bonzo')

    Polymer 'conference-room',
      audioon: true
      videoon: true
      userprofiles: {}
      calls: []
      attached: ->

        @addEventListener 'error', (err) ->
          console.log err

All the calls known to the application, make sure there are visual elements.

        document.addEventListener 'calls', (evt) =>
          calls = _.groupBy evt.detail, (x) -> x.id
          visibleCalls = _.map @calls, (x) -> x.id
          currentCalls = _.map evt.detail, (x) -> x.id
          _.difference(currentCalls, visibleCalls).forEach (id) =>
            @calls.push calls[id][0]
          _.difference(visibleCalls, currentCalls).forEach (id) =>
            @shadowRoot.querySelector("#A#{id}").hideAnimated =>
              _.remove @calls, (x) -> x.id is id

User profiles coming in from the server are captured here.

        document.addEventListener 'userprofiles', (evt) =>
          @userprofiles = evt.detail
          @fire 'call', to: evt.detail.sessionid

Show and hide the selfie -- this really needs to be data bound instead.

        @addEventListener 'selfie.on', =>
          @$.selfie.showAnimated()
        @addEventListener 'selfie.off', =>
          @$.selfie.hideAnimated()

Administrative actions on the tool and sidebar go here.

        @addEventListener 'sidebar', ->
          @$.sidebar.toggle()

Clear out autocomplete results. Pay attention to this one, multiple text input
elements that can fire clear will totally overdo it.

        @addEventListener 'clear', (evt) =>
          @fire 'autocomplete',
            search: undefined
            results: []

Show those results via data binding. This message is coming back in from the
server.

        document.addEventListener 'autocomplete', (evt) =>
          @$.searchresults.model =
            profiles: evt.detail.results

        setTimeout =>
          @fire 'sidebar'

WebRTC can only kick off interaction when it has something to share, namely a
local stream of data to transmit. Listen for this stream and set it so that it
can be bound by all the contained calls.

      localstreamChanged: ->
        @fire 'getcalls', {}
        @fire 'login', {}
