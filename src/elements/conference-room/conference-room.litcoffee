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
    config = require('../../config.yaml')?[chrome.runtime.id]

    Polymer 'conference-room',
      attached: ->
        @sessionid = uuid.v1()
        @calls = []
        @profiles = {}
        @config = config

This is the startup routine that registers with the signalling server.

        debugcall = true
        startup = =>
          @$.local.fire 'register',
            sessionid: @sessionid
            calls: @calls
          @$.local.fire 'userprofiles', @profiles
          if debugcall
            debugcall = false
            @$.local.fire 'call',
              to: @sessionid

WebRTC kicks off interaction when it has something to share, namely a local
stream of data to transmit. Listen for this stream and set it so that
it can be bound by all the contained calls.

        @addEventListener 'localstream', (evt) =>
          @localStream = evt.detail
          @$.local.fire 'getuserprofile'

Profiles coming in from OAuth, there is just Github at the moment, but hash
this with a source anyhow. This gets triggered as a result of the
`getuserprofile` event request being relayed to the background page.

        @addEventListener 'userprofile', (evt) =>
          console.log 'profile', evt.detail
          @profiles[evt.detail.profile_source] = evt.detail
          startup()

Set up inbound and outbound calls when asked by adding an element via data
binding. Polymer magic.

        @addEventListener 'outboundcall', (evt) ->
          @calls.push evt.detail

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

        @addEventListener 'hangup', (evt) ->
          _.remove @calls, (call) ->
            call.callid is evt.detail.callid and evt.detail.signal

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

On connection or reconnection, as for a user profile otherwise not much will
be useful.

        @addEventListener 'connect', =>
          startup()
        @addEventListener 'reconnect', =>
          startup()

This is just debug code. Remove later. Really. No fooling.

        setTimeout =>
          @fire 'sidebar'

