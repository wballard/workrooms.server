The conference room is a lot like a controller, bringing together
multiple different elements and coordinating them. In particular, this
element is responsible for taking events from `RTCPeerConnection` objects in
scope and sending them along to the signalling server in order to set up
peer-to-peer communication.

This differs from a controller in that only the DOM scoping is used, events
bubble up from contained elements, and messages are send back down
via method calls and property sets. Nice and simple.

#Attributes
##config
All the settings, these are loaded up from disk and keyed by the local
chrome extension ID.
##localStream
This is your local video/audio data stream.
##calls
Array of all active calls metadata. These aren't calls themselves, just
identifiers used to data bind and generate `ui-video-call` elements.

    uuid = require('node-uuid')
    _ = require('lodash')
    qwery = require('qwery')
    bonzo = require('bonzo')

    Polymer 'conference-room',
      attached: ->
        @calls = []

        @addEventListener 'error', (err) ->
          console.log err

WebRTC kicks off interaction when it has something to share, namely a local
stream of data to transmit. Listen for this stream and set it so that
it can be bound by all the contained calls.

One trick, this fires on element `local` so that it bubbles up to the chrome
bridge and is carried away.

        @addEventListener 'localstream', (evt) =>
          @localStream = evt.detail
          @$.local.fire 'register',
            runtime: chrome.runtime.id
            calls: @calls

        @addEventListener 'hello', (evt) =>
          @$.local.fire 'register',
            runtime: chrome.runtime.id
            calls: @calls

The server will need to know all about your calls if you reconnect.
This also adds debugging support to quickly call yourself from the console.

        @addEventListener 'configured', (evt) =>
          window.debugCallSelf = =>
            @$.local.fire 'call', to: evt.detail.sessionid
          window.debugCallFail = =>
            @$.local.fire 'call', to: 'fail'

Set up inbound and outbound calls when asked by adding an element via data
binding. Polymer magic.

        @addEventListener 'outboundcall', (evt) ->
          @calls.push evt.detail
          @$.local.fire 'calls', @calls

        @addEventListener 'inboundcall', (evt) ->
          ###
          url = evt?.detail?.userprofiles?.github?.avatar_url
          callToast = webkitNotifications.createNotification url, 'Call From', evt.detail.userprofiles.github.name
          callToast.onclick = ->
            chrome.runtime.sendMessage
              showConferenceTab: true
          callToast.show()
          ###
          @calls.push evt.detail
          @$.local.fire 'calls', @calls

        @addEventListener 'hangup', (evt) ->
          console.log 'hangup', evt
          _.forEach evt?.detail?.calls or [], (hangupCall) =>
            _.remove @calls, (call) ->
              console.log 'hangup', call, @calls
              call.callid is hangupCall.callid
          @$.local.fire 'calls', @calls

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

        @addEventListener 'autocomplete', (evt) =>
          @$.searchProfiles.model =
            profiles: evt.detail.results


This is just debug code. Remove later. Really. No fooling.

        setTimeout =>
          @fire 'sidebar'

