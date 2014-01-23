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

    Polymer 'conference-room',
      attached: ->
        @calls = []
        @config = config

WebRTC kicks off interaction when it has something to share, namely a local
stream of data to transmit. Listen for this stream and set it so that
it can be bound by all the contained calls.

Oh -- and -- when a local stream is available, make sure to ask if there
are any calls queued up to process!

        @addEventListener 'localstream', (evt) =>
          @localStream = evt.detail
          chrome.runtime.sendMessage
            dequeueCalls: true

OK -- so this is the tricky bit, it isn't worth asking to connect calls until
the local stream is available.

The `.fire.fire` bit is going to a nested element so that it gets caught by
the surrounding websocket.

        chrome.runtime.onMessage.addListener (message, sender, respond) =>
          if message.call and @localStream
            chrome.runtime.sendMessage
              dequeueCalls: true
          if message.makeCalls
            message.makeCalls.forEach (call) =>
              call.callid = uuid.v1()
              @$.fire.fire 'call', call

Set up inbound and outbound calls when asked by adding an element.

        @addEventListener 'outboundcall', (evt) ->
          evt.detail.outbound = true
          @calls.push evt.detail
        @addEventListener 'inboundcall', (evt) ->
          evt.detail.inbound = true
          ###
          url = evt?.detail?.userprofiles?.github?.avatar_url
          callToast = webkitNotifications.createNotification url, 'Call From', evt.detail.userprofiles.github.name
          callToast.onclick = ->
            chrome.runtime.sendMessage
              showConferenceTab: true
          callToast.show()
          ###
          @calls.push evt.detail

Keep track of OAuth supplied user profiles, and hotwire a call for testing.

        @addEventListener 'userprofile', (evt) =>
          @$.fire.fire 'call',
            callid: uuid.v1()
            to:
              gravatar: evt.detail.gravatar_id

And call control messages for connected calls. This also heartbeats the mute
status, similar to the user profiles.

* *TODO* use peer to peer messaging for the mute controls

        muteStatus =
          sourcemutedvideo: false
          sourcemutedaudio: false
        signalMuteStatus = =>
          bonzo(qwery('ui-video-call', @shadowRoot)).each (call) =>
            @$.fire.fire 'mutestatus',
              sourcemutedaudio: muteStatus.sourcemutedaudio
              sourcemutedvideo: muteStatus.sourcemutedvideo
              callid: call.callid
              peerid: call.peerid
        setInterval signalMuteStatus, @keepalive * 1000
        @addEventListener 'audio.on', (evt) ->
          muteStatus.sourcemutedaudio = false
          signalMuteStatus()
        @addEventListener 'audio.off', (evt) ->
          muteStatus.sourcemutedaudio = true
          signalMuteStatus()
        @addEventListener 'video.on', (evt) ->
          muteStatus.sourcemutedvideo = false
          signalMuteStatus()
        @addEventListener 'video.off', (evt) ->
          muteStatus.sourcemutedvideo = true
          signalMuteStatus()

Administrative actions on the tool and sidebar go here.

        @addEventListener 'sidebar', ->
          @$.sidebar.toggle()

        @addEventListener 'clear', (evt) =>
          @fire 'searchresults', []

        document.addEventListener 'autocompleteresults', (evt) =>
          @$.searchProfiles.model =
            profiles: evt.detail.results

This is just debug code.

        setTimeout =>
          @fire 'sidebar'

