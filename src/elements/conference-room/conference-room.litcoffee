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
      userprofiles: {}
      calls: []
      attached: ->


        @addEventListener 'error', (err) ->
          console.log err

WebRTC can only kick off interaction when it has something to share, namely a
local stream of data to transmit. Listen for this stream and set it so that it
can be bound by all the contained calls.

        @addEventListener 'localstream', (evt) =>
          @localstream = evt.detail
          @fire 'getcalls', {}
          @fire 'getuserprofiles', {}

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

        document.addEventListener 'userprofiles', (evt) =>
          @userprofiles = evt.detail

In call options, most important of which is mute audio / mute video. This just
fires an event, counting on the individual calls to listen for it and then
send to one another peer-to-peer.

        muteStatus =
          sourcemutedvideo: false
          sourcemutedaudio: false
        @addEventListener 'audio.on', (evt) ->
          muteStatus.sourcemutedaudio = false
          @fire 'mutestatus', muteStatus
        @addEventListener 'audio.off', (evt) ->
          muteStatus.sourcemutedaudio = true
          @fire 'mutestatus', muteStatus
        @addEventListener 'video.on', (evt) ->
          muteStatus.sourcemutedvideo = false
          @fire 'mutestatus', muteStatus
        @addEventListener 'video.off', (evt) ->
          muteStatus.sourcemutedvideo = true
          @fire 'mutestatus', muteStatus
        @addEventListener 'selfie.on', ->
          console.log 'onn', @$.selfie
          @$.selfie.showAnimated()
        @addEventListener 'selfie.off', ->
          console.log 'off'
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
          console.log 'a', evt.detail.results
          @$.searchresults.model =
            profiles: evt.detail.results

This is just debug code. Remove later. Really. No fooling.

        setTimeout =>
          @fire 'sidebar'

