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

##Toolbar Buttons

Show and hide the selfie -- this really needs to be data bound instead.

        @addEventListener 'selfie.on', =>
          @$.selfie.showAnimated()
        @addEventListener 'selfie.off', =>
          @$.selfie.hideAnimated()

Sidebar, are you even allowed to have an application without one any more?

        @addEventListener 'sidebar', ->
          @$.sidebar.toggle()
        @addEventListener 'chatbar', ->
          @$.chatbar.toggle()

Login and Logout, this is just a message relay to the background

        @addEventListener 'logout', =>
          @backgroundChannel.send 'logout'

        @addEventListener 'login', =>
          @backgroundChannel.send 'login'

##Call Signal Processing

Ending calls. Not a lot to do here but request through to the application.

        @addEventListener 'hangup', =>
          @backgroundChannel.send 'hangup'

        @addEventListener 'ice', (evt) =>
          @backgroundChannel.send 'ice', evt.detail
        @conferenceChannel.on 'ice', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processIce detail

        @addEventListener 'offer', (evt) =>
          @backgroundChannel.send 'offer', evt.detail
        @conferenceChannel.on 'offer', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processOffer detail

        @addEventListener 'answer', (evt) =>
          @backgroundChannel.send 'answer', evt.detail
        @conferenceChannel.on 'answer', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processAnswer detail

##Autocomplete Search

Clear out autocomplete results. Pay attention to this one, multiple text input
elements that can fire clear will totally overdo it.

        @addEventListener 'clear', (evt) =>
          @$.searchresults.model =
            profiles: []

        document.addEventListener 'autocomplete', (evt) =>
          @backgroundChannel.send 'autocomplete', evt.detail

        @conferenceChannel.on 'autocomplete', (detail) =>
          @$.searchresults.model =
            profiles: detail.results

        document.addEventListener 'call', (evt) =>
          @backgroundChannel.send 'call', evt.detail

##Chat

Hook up chat message processing, most important thing is to attach your local
user identity to messages as they are posted. This will send messages as they
are posted to the connected WebRTC calls on the page so everyone gets a chat.

        @$.chat.addEventListener 'message', (evt) =>
          evt.stopPropagation()
          message =
            who: @userprofiles?.github?.name or @userprofiles?.github?.login or 'Anonymous'
            what: evt.detail.what
            when: evt.detail.when
          evt.detail.callback undefined, message
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.send 'message', message

        @addEventListener 'message', (evt) =>
          evt.detail.when = new Date()
          @$.chat.addMessage evt.detail

        @$.chat.addEventListener 'chunk', (evt) =>
          evt.detail.callback undefined, 0, 0, []

WebRTC can only kick off interaction when it has something to share, namely a
local stream of data to transmit. Listen for this stream and set it so that it
can be bound by all the contained calls.

      localstreamChanged: ->
        @backgroundChannel.send 'getcalls'
        @backgroundChannel.send 'login'


