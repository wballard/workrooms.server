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
##nametag
A string that is all about who you are.

    require '../elementmixin.litcoffee'
    uuid = require 'node-uuid'
    _ = require 'lodash'
    _.str = require 'underscore.string'
    bowser = require 'bowser'
    SignallingServer = require '../../scripts/signalling-server.litcoffee'
    getScreenMedia = require 'getscreenmedia'

    Polymer 'conference-room',

#Screen Sharing
Sharing a screen -- just buffer it so we can data bind for display.

      screenSharing: (screenStream) ->
        screen =
          screenid: screenStream.id
          fromclientid: @signallingServer.clientid
          stream: screenStream
          shares: []
        @sharedscreens.push screen

A screen is fully shared when it has a snapshot ready. So, if it is a local
screen with an actual stream, send it along so that other room members can know.

      screenShared: (evt) ->
        screen = evt.detail
        if screen.stream
          @signallingServer.send 'screen',
            screenid: screen.screenid
            fromclientid: screen.fromclientid
            snapshot: screen.snapshot

      screenUnshared: (evt) ->
        screen = evt.detail
        _.remove @sharedscreens, (s) -> s.screenid is screen.screenid
        @signallingServer.send 'deletescreen',
          screenid: screen.screenid

#Room Selection

      roomSelectorKeypressed: ->
        window.location.hash = "/" + _.str.dasherize @$.roomSelector.value?.toLowerCase()

      roomChanged: _.debounce ->
        if @roomLabel.length
          @signallingServer.send 'register',
            room: @room
      , 500

#Calling
Set up a call by signalling to the server. This instructs the server to
tell each peer to set up inbound and outbound peer calls.

      call: (clientid) ->
        if clientid
          @signallingServer.send 'call',
            to: clientid

#Polymer Lifecycle
Main thing going on here it setting up signalling service, which isn't an
element, it is just code.

      ready: ->
        @fire 'ready'

      attached: ->
        if bowser.browser.chrome
          @$.chromeonly.hide()
        else
          @shadowRoot.querySelector('ui-mainbar').hide()
        @nametag = 'Anonymous'
        @audioon = true
        @videoon = true
        @serverconfig = null
        @calls = []
        @chatCount = 0
        @focused = true
        @sharedscreens = []
        @roomLabel = _.str.humanize window.location.hash?.replace('#/', '')
        @root = "#{document.location.origin}#{document.location.pathname}"
        if not @root.match(/^https/i)
          window.location = "https://#{document.location.host}#{document.location.pathname}#{document.location.hash}"
        if @root.slice(-1) isnt '/'
          @root += '/'
        @signallingServer = new SignallingServer("ws#{@root.slice(4)}")
        @signallingServer.on 'error', (err) ->
          console.log err
        @addEventListener 'error', (err) ->
          console.log err

##Setting Up Signalling
Hello from the server! The roomChanged event handler will hook the rest of the registration

        @signallingServer = new SignallingServer("ws#{@root.slice(4)}")

        @signallingServer.on 'error', (err) ->
          console.log err

        @signallingServer.on 'hello', =>
          @fire 'hello'

        @signallingServer.on 'pong', (hashes) =>
          @fire 'pong', hashes

##Toolbar Buttons

Sidebars, are you even allowed to have an application without one any more?

         @addEventListener 'chatbar.on', =>
          @$.chatbar.visible = true
          @chatCount = 0

        @addEventListener 'chatbar.off', =>
          @$.chatbar.visible = false

Screensharing, this asks for a screen to share and adds it to the room.

        @addEventListener 'screenshare', =>
          if document.getElementById('workrooms-extension-is-installed')
            getScreenMedia (err, screenStream) =>
              if err
                @fire 'error', err
              else
                console.log screenStream
                @screenSharing screenStream
          else
            chrome.webstore.install "https://chrome.google.com/webstore/detail/hndpmcmfdenfebmdoakeeeinlllkhapk", =>
              @fire 'screenshare'
            , (err) =>
              console.log 'extension install failed', err

##Call Tracking
Keeps track of all your calls, and forwards them to all connected call
peers in order to support auto-conference.

        callOverlap = (a, b) ->
          a.fromclientid is b.fromclientid and a.toclientid is b.toclientid

        takeCall = (newCall) =>
          if not _.any(@calls, (call) -> callOverlap(newCall, call))
            @calls.push newCall

        @signallingServer.on 'outboundcall', takeCall

        @signallingServer.on 'inboundcall', takeCall

##Room State
When the room list changes, place calls. This uses a simply bully algorithm
where the larger client id is in charge of actually making the call.

        @signallingServer.on 'roomlist', (clientids) =>
          for clientid in clientids
            if clientid < @signallingServer.clientid
              @call clientid
          _.remove @calls, (call) ->
            call.fromclientid not in clientids or call.toclientid not in clientids

When the room screens change, track the screens locally in the room. No call
is made, these just put thumbnails of a screen in other peers rooms, while
in your own screen you have the original with the actual stream object that
witll be shared peer-to-peer.

        @signallingServer.on 'roomscreens', (screens) =>
          screens.forEach (screen) =>
            existing =  _.find(@sharedscreens, (s) -> s.screenid is screen.screenid)
            if existing
              existing.snapshot = screen.snapshot
            else
              @sharedscreens.push screen
          ids = _.object _.pluck(screens, 'screenid'), _.pluck(screens, 'screenid')
          removed = _.remove @sharedscreens, (screen) -> not ids[screen.screenid] and not screen.stream

##Screen Call Tracking
Screen request for this peer to push a screen.

        @signallingServer.on 'outboundscreen', (newScreen) =>
          _(@sharedscreens)
            .select (s) -> s.screenid is newScreen.screenid
            .each (s) ->
              if not _.any(s.shares, (screen) -> callOverlap(newScreen, screen))
                s.shares.push newScreen

##Call Signal Processing
Relay signalling server messages into the calls.

        @addEventListener 'ice', (evt) =>
          evt.detail.nolog = true
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

##Chat
Hook up chat message processing, most important thing is to attach your local
user identity to messages as they are posted. This will send messages as they
are posted to the connected WebRTC calls on the page so everyone gets a chat.

        @$.chat.addEventListener 'message', (evt) =>
          evt.stopPropagation()
          message =
            who: @nametag
            what: evt.detail.what
            when: evt.detail.when
          evt.detail.callback undefined, message
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.send 'message', message

        @addEventListener 'message', (evt) =>
          evt.detail.when = new Date()
          @$.chat.addMessage evt.detail
          @chatCount++ unless @$.chatbar.visible

        @$.chat.addEventListener 'chunk', (evt) =>
          evt.detail.callback undefined, 0, 0, []

        @$.chat.addEventListener 'typing', _.debounce =>
          message =
            who: @nametag
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.send 'typing', message
        , 1000, leading: true

        @addEventListener 'typing', (evt) =>
          @$.chat.typerName = evt?.detail?.who

        @$.chat.addEventListener 'not-typing', =>
          message =
            who: @nametag
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.send 'not-typing', message

        @addEventListener 'not-typing', (evt) =>
          @$.chat.typerName = ""

