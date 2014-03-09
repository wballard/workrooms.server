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
    ChromeEventEmitter = require('../../scripts/chrome-event-emitter.litcoffee')

    Polymer 'conference-room',
      backgroundChannel: new ChromeEventEmitter('background')
      conferenceChannel: new ChromeEventEmitter('conference')
      audioon: true
      videoon: true
      userprofiles: {}
      calls: []
      attached: ->
        @addEventListener 'error', (err) ->
          console.log err

All the calls known to the application, make sure there are visual elements.

        @conferenceChannel.on 'calls', (calls) =>
          calls = _.groupBy calls, (x) -> x.id
          visibleCalls = _.map @calls, (x) -> x.id
          _.difference(_.keys(calls), visibleCalls).forEach (id) =>
            @calls.push calls[id][0]
          _.difference(visibleCalls, _.keys(calls)).forEach (id) =>
            @shadowRoot.querySelector("#A#{id}").hideAnimated =>
              _.remove @calls, (x) -> x.id is id

User profiles coming in from the server are captured here.

        @conferenceChannel.on 'userprofiles', (userprofiles) =>
          @userprofiles = userprofiles
          @backgroundChannel.send 'call', to: userprofiles.sessionid

##Toolbar Buttons

Show and hide the selfie -- this really needs to be data bound instead.

        @addEventListener 'selfie.on', =>
          @$.selfie.showAnimated()
        @addEventListener 'selfie.off', =>
          @$.selfie.hideAnimated()

Sidebar, are you even allowed to have an application without one any more?

        @addEventListener 'sidebar', ->
          @$.sidebar.toggle()

Login and Logout, this is just a message relay to the background

        @addEventListener 'logout', =>
          @backgroundChannel.send 'logout'

        @addEventListener 'login', =>
          @backgroundChannel.send 'login'

Ending calls. Not a lot to do here but request through to the application.

        @addEventListener 'hangup', =>
          @backgroundChannel.send 'hangup'

##Autocomplete Search

Clear out autocomplete results. Pay attention to this one, multiple text input
elements that can fire clear will totally overdo it.

        @addEventListener 'clear', (evt) =>
          @$.searchresults.model =
            profiles: []

        document.addEventListener 'autocomplete', (evt) =>
          console.log 'to bg'
          @backgroundChannel.send 'autocomplete', evt.detail

        @conferenceChannel.on 'autocomplete', (detail) =>
          @$.searchresults.model =
            profiles: detail.results

        document.addEventListener 'call', (evt) =>
          @backgroundChannel.send 'call', evt.detail

WebRTC can only kick off interaction when it has something to share, namely a
local stream of data to transmit. Listen for this stream and set it so that it
can be bound by all the contained calls.

      localstreamChanged: ->
        @backgroundChannel.send 'getcalls'
        @backgroundChannel.send 'login'

