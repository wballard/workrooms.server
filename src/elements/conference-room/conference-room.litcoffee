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
##serverconfig
The server literally sends the config back to the client on a connect.

    require('../elementmixin.litcoffee')
    uuid = require('node-uuid')
    _ = require('lodash')
    qwery = require('qwery')
    bonzo = require('bonzo')
    SignallingServer = require('../../scripts/signalling-server.litcoffee')

    Polymer 'conference-room',
      audioon: true
      videoon: true
      userprofiles: {}
      calls: []
      serverconfig: null

      attached: ->
        @signallingServer = new SignallingServer("ws#{document.location.origin.slice(4)}")
        @addEventListener 'error', (err) ->
          console.log err

##Signalling Server Messages
Hello from the server! Now it is time to register this client in order to
get the rest of the configuration. Sending along the calls is an 'autoreconnect'.

        @signallingServer.on 'hello', =>
          @signallingServer.send 'register',
            runtime: document.location.host
            calls: @calls
            userprofiles: @userprofiles

After we have registered, the server sends along a configuration, this is to
protect -- or really to be able to switch -- ids for OAuth and STUN/TURN.

        @signallingServer.on 'configured', (config) =>
          console.log 'configured', config
          @serverConfig = config
          @userprofiles = config.userprofiles

##Toolbar Buttons

Show and hide the selfie -- this really needs to be data bound instead.

        @addEventListener 'selfie.on', =>
          @$.selfie.showAnimated()
        @addEventListener 'selfie.off', =>
          @$.selfie.hideAnimated()

Sidebars, are you even allowed to have an application without one any more?

        @$.sidebar.hideAnimated()
        @$.chatbar.hideAnimated()
        @addEventListener 'sidebar', =>
          @$.sidebar.toggle()
        @addEventListener 'chatbar', =>
          @$.chatbar.toggle()

##Call Tracking

        @signallingServer.on 'outboundcall', (detail) =>
          detail.config = @serverConfig
          @calls.push detail

        @signallingServer.on 'inboundcall', (detail) =>
          detail.config = @serverConfig
          @calls.push detail

**TODO** figure out how to track if this tab is active

          tabActive = true
          if not tabActive
            url = detail?.userprofiles?.github?.avatar_url
            callToast = webkitNotifications.createNotification url, 'Call From', detail.userprofiles.github.name
            callToast.onclick = =>
              conferenceTab.show()
            callToast.show()

##Hangup Tracking
Hangup handling, when this is coming up the page, it is a signal to hang up all
calls. When from the server, it is information to hang up one call.

        @addEventListener 'hangup', =>
          @calls.forEach (call) =>
            @signallingServer.send 'hangup', call

        @signallingServer.on 'hangup', (hangupCall) =>
          _.remove @calls, (call) -> call.callid is hangupCall.callid

##Call Signal Processing

        @addEventListener 'ice', (evt) =>
          @signallingServer.send 'ice', evt.detail
        @signallingServer.on 'ice', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processIce detail

        @addEventListener 'offer', (evt) =>
          @signallingServer.send 'offer', evt.detail
        @signallingServer.on 'offer', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processOffer detail

        @addEventListener 'answer', (evt) =>
          @signallingServer.send 'answer', evt.detail
        @signallingServer.on 'answer', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processAnswer detail

        @addEventListener 'call', (evt) =>
          @signallingServer.send 'call', evt.detail

##Autocomplete Search

Clear out autocomplete results. Pay attention to this one, multiple text input
elements that can fire clear will totally overdo it.

        @addEventListener 'clear', (evt) =>
          @$.searchresults.model =
            profiles: []

        document.addEventListener 'autocomplete', (evt) =>
          @signallingServer.send 'autocomplete', evt.detail

        @signallingServer.on 'autocomplete', (detail) =>
          @$.searchresults.model =
            profiles: detail.results


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
