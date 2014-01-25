The conference room is a lot like a controller, bringing together
multiple different elements and coordinating them. In particular, this
element is responsible for taking events from `RTCPeerConnection` objects in
scope and sending them along to the signalling server in order to set up
peer-to-peer communication.

This differs from a controller in that only the DOM scoping is used, events
bubble up from contained elements, and messages are send back down
via method calls and property sets. Nice and simple.

#Message Pattern
All calls have an outbound (you call) and an inbound (you were called) side
to match up with WebRTC's expectations.

All calls have a .id which is unique to each call, and is used
as the correlation key between the inbound and outbound side
to set up peer-peer traffic.

##Connecting State
Connecting relays through the server to find another peer to call, and
if possible, sets up a local `outboundcall`. Similarly the called side
gets a `inboundcall`.
```
  (call) -> server
  calling client <- (outboundcall | notavailable)
  called client <- (inboundcall)
```
##Connected State
When connected, calls can be modified by either side by relaying messages
though the signalling server.
**TODO** should these go peer-to-peer instead over a data channel?
```
  (mute | unmute | hangup) -> server
  any client <- (mute | unmute | hangup)
```

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
    Q = require('q')

    Polymer 'conference-room',
      attached: ->
        @calls = []
        @profiles = {}
        @config = config
        @localStreamReady = Q.defer()
        @profilesReady = Q.defer()
        Q.all([@localStreamReady.promise, @profilesReady.promise]).then =>
          console.log 'ready'
          @$.local.fire 'ready',
            profiles: @profiles
            calls: []
          @fire 'debugready'

WebRTC kicks off interaction when it has something to share, namely a local
stream of data to transmit. Listen for this stream and set it so that
it can be bound by all the contained calls.


        @addEventListener 'localstream', (evt) =>
          @localStream = evt.detail
          @localStreamReady.resolve(@localStream)
          @$.local.fire 'getuserprofile'

Profiles coming in from OAuth, there is just Github at the moment, but hash
this with a source anyhow. This gets triggered as a result of the
`getuserprofile` event request being relayed to the background page.

        @addEventListener 'userprofile', (evt) =>
          console.log 'profile', evt.detail
          @profiles[evt.detail.profile_source] = evt.detail
          @profilesReady.resolve(@profiles)

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
          @fire 'autocompleteresults', []

Show those results via data binding. This message is coming back in from the
server.

        @addEventListener 'autocompleteresults', (evt) =>
          @$.searchProfiles.model =
            profiles: evt.detail.results

On connection or reconnection, as for a user profile otherwise not much will
be useful.

        @addEventListener 'connect', =>
          if @localStream and @profiles
            @$.local.fire 'ready',
              profiles: @profiles
              calls: @calls
        @addEventListener 'reconnect', =>
          if @localStream and @profiles
            @$.local.fire 'ready',
              profiles: @profiles
              calls: @calls

This is just debug code. Remove later. Really. No fooling.

        setTimeout =>
          @fire 'sidebar'

        @addEventListener 'debugready', (evt) =>
          setTimeout =>
            @$.local.fire 'call',
              callid: uuid.v1()
              to:
                gravatar: @profiles.github.gravatar_id
