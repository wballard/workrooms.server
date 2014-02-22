The conference room is a lot like a controller, bringing together
multiple different elements and coordinating them. In particular, this
element is responsible for taking events from `RTCPeerConnection` objects in
scope and sending them along to the signalling server in order to set up
peer-to-peer communication.

This differs from a controller in that only the DOM scoping is used, events
bubble up from contained elements, and messages are send back down
via method calls and property sets. Nice and simple.

#Attributes
##serverConfig
All the settings supplied through by the server.
##localstream
This is your local video/audio data stream.
##calls
Array of all active calls metadata. These aren't calls themselves, just
identifiers used to data bind and generate `ui-video-call` elements.

    uuid = require('node-uuid')
    _ = require('lodash')
    qwery = require('qwery')
    bonzo = require('bonzo')

    Polymer 'conference-room',
      userprofiles: {}
      attached: ->
        @calls = []

        @addEventListener 'error', (err) ->
          console.log err

WebRTC kicks off interaction when it has something to share, namely a local
stream of data to transmit. Listen for this stream and set it so that
it can be bound by all the contained calls.

        @addEventListener 'localstream', (evt) =>
          @localstream = evt.detail
          @fire 'register',
            runtime: chrome.runtime.id
            calls: @calls

When the server says hello, tell it about the local calls we may already have.
This lets the server live through a crash by having all the clients keep it
up to date.

        document.addEventListener 'hello', (evt) =>
          @fire 'register',
            runtime: chrome.runtime.id
            calls: @calls

Capture the config from the server, this has important settings like where to
do STUN/TURN.

        document.addEventListener 'userprofiles', (evt) =>
          @userprofiles = evt.detail
          console.log 'profiles', @userprofiles

        document.addEventListener 'configured', (evt) =>
          @serverConfig = evt.detail
          window.debugCallSelf = =>
            @fire 'call', to: evt.detail.sessionid
          @addEventListener 'debugcallself', =>
            window.debugCallSelf()
          window.debugCallFail = =>
            @fire 'call', to: 'fail'

Set up inbound and outbound calls when asked by adding an element via data
binding. Polymer magic.

        document.addEventListener 'outboundcall', (evt) =>
          @calls.push evt.detail
          @fire 'calls', @calls

        document.addEventListener 'inboundcall', (evt) =>
          ###
          url = evt?.detail?.userprofiles?.github?.avatar_url
          callToast = webkitNotifications.createNotification url, 'Call From', evt.detail.userprofiles.github.name
          callToast.onclick = ->
            chrome.runtime.sendMessage
              showConferenceTab: true
          callToast.show()
          ###
          @calls.push evt.detail
          @fire 'calls', @calls

        document.addEventListener 'hangup', (evt) =>
          console.log 'hangup', evt
          _.forEach evt?.detail?.calls or [], (hangupCall) =>
            _.remove @calls, (call) ->
              console.log 'hangup', call, @calls
              call.callid is hangupCall.callid
          @fire 'calls', @calls

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
          bonzo(@$.selfie).show()
        @addEventListener 'selfie.off', ->
          bonzo(@$.selfie).hide()

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

