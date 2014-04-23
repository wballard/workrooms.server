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
    kizzy = require('kizzy')
    hummingbird = require('hummingbird')
    SignallingServer = require('../../scripts/signalling-server.litcoffee')

    Polymer 'conference-room',

      ready: ->
        @fire 'ready'

      attached: ->
        @audioon = true
        @videoon = true
        @serverconfig = null
        @store = kizzy('conferenceroom')
        @userprofiles = null
        @calls = @store.get('calls') or []
        @root = "#{document.location.origin}#{document.location.pathname}"
        if @root.slice(-1) isnt '/'
          @root += '/'
        @signallingServer = new SignallingServer("ws#{@root.slice(4)}")
        @addEventListener 'error', (err) ->
          console.log err

##Setting Up Signalling
Hello from the server! Now it is time to register this client in order to
get the rest of the configuration.

        @signallingServer.on 'hello', =>
          @signallingServer.send 'register',
            runtime: document.location.host

After we have registered, the server sends along a configuration, this is to
protect -- or really to be able to switch -- ids for OAuth and STUN/TURN.

        @signallingServer.on 'configured', (config) =>
          @serverConfig = config

When OAuth is complete, or restored from a saved session, the server will
provide you with profiles.

        @signallingServer.on 'userprofiles', (userprofiles) =>
          @userprofiles = userprofiles

And sometimes you just have to let go.

        @signallingServer.on 'disconnect', =>
          @signallingServer.close()
          @signallingServer = null

##Toolbar Buttons

Show and hide the selfie -- this really needs to be data bound instead.

        @addEventListener 'selfie.on', =>
          @$.selfie.showAnimated()
        @addEventListener 'selfie.off', =>
          @$.selfie.hideAnimated()

Sidebars, are you even allowed to have an application without one any more?

        @addEventListener 'sidebar', =>
          @$.sidebar.toggle()
        @addEventListener 'chatbar', =>
          @$.chatbar.toggle()

##Call Tracking

Keeps track of all your calls, and forwards them to all connected call
peers in order to support auto-conference.

This has a bit of a hack to allow self calls for testing

        callOverlap = (a, b, hackSelf) ->
          if b.fromclientid is b.toclientid and hackSelf
            console.log 'self call check'
            selfInbound = a.fromclientid is b.fromclientid and
              a.toclientid is b.toclientid and
              a.inbound is b.inbound
            selfOutbound = a.fromclientid is b.fromclientid and
              a.toclientid is b.toclientid and
              a.outbound is b.outbound
          else
            a.fromclientid is b.fromclientid or
              a.toclientid is b.toclientid or
              a.fromclientid is b.toclientid or
              a.toclientid is b.fromclientid

        takeCall = (newCall) =>
          if _.any(@calls, (call) -> callOverlap(call, newCall, true))
            console.log 'already connected'
          else
            newCall.config = @serverConfig
            @calls.push newCall
            @store.set('calls', @calls)

**TODO** figure out how to track if this tab is active

          tabActive = true
          if not tabActive
            url = detail?.userprofiles?.github?.avatar_url
            callToast = webkitNotifications.createNotification url, 'Call From', detail.userprofiles.github.name
            callToast.onclick = =>
              conferenceTab.show()
            callToast.show()

        @signallingServer.on 'outboundcall', takeCall

        @signallingServer.on 'inboundcall', takeCall

        @addEventListener 'callkeepalive', (evt) =>

##Hangup Tracking
Hanging up is either about one or all calls depending on whic button
was pushed
Hangup handling, when this is coming up the page, it is a signal to hang up all
calls. When from the server, it is information to hang up one call.

        @addEventListener 'hangup', (evt) =>
          if evt.detail.fromclientid and evt.detail.toclientid
            @signallingServer.send 'hangup',
              fromclientid: evt.detail.fromclientid
              toclientid: evt.detail.toclientid
          else
            _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) =>
              @signallingServer.send 'hangup',
                fromclientid: call.fromclientid
                toclientid: call.toclientid

        @signallingServer.on 'hangup', (hangupCall) =>
          _.remove @calls, (call) -> callOverlap(hangupCall, call)
          @store.set('calls', @calls)

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
          message = _.extend evt.detail,
            from:
              userprofiles: @userprofiles
          @signallingServer.send 'call', evt.detail
        window.debugFailCall = =>
          @signallingServer.send 'call', to: 'fail'

##Autocomplete Search

Clear out autocomplete results. Pay attention to this one, multiple text input
elements that can fire clear will totally overdo it.

        showFriends = (friends) =>
          @$.searchresults.model =
            friends:
              _(friends or @profileIndex?.friends or [])
                .values()
                .sortBy (friend) -> friend.name.toLowerCase()
                .value()

        @addEventListener 'clear', (evt) =>
          showFriends()

        @addEventListener 'autocomplete', (evt) =>
          @profileIndex?.search evt.detail.search, (results) =>
            showFriends(results)
          , scoreThreshold: 0.1

When new friends are discovered, update the index locally so we can find them.
And then re-bind the user interface to the friend list.

        @addEventListener 'newfriends', (evt) =>
          if evt?.detail
            @profileIndex = profileIndex = new hummingbird.Index()
            profileIndex.friends = evt.detail
            profileIndex.by_github_id = {}
            profileIndex.prep = (user) ->
              user.id = user.userprofiles.github.id
              if user.userprofiles?.github?.name
                user.name = user.userprofiles.github.name
              else
                user.name = user.userprofiles.github.login
              user
            _.values(evt.detail)
              .forEach (friend) ->
                profileIndex.add profileIndex.prep(friend), false
                profileIndex.by_github_id["#{friend.userprofiles.github.id}"] = friend
            showFriends()
            @signallingServer.send 'isonline',
              githubFriends: _.values(@profileIndex.friends or []).map (friend) -> friend.userprofiles.github.id
              userprofiles: @userprofiles

When asked if you are online, come back with your profile. This is a message
froma single friend peer, much like signalling.

        @signallingServer.on 'isonline', (user) =>
          _.extend user, userprofiles: @userprofiles
          @signallingServer.send 'online', user

When someone tells you they are online, update your local index copy of their
profile. This is a message that will originate from a friend peer, much like
signalling.
This message also reciprocates, which lets you learn that a requestor is online
if they came online after you did your initial batch request.

        @signallingServer.on 'online', (user) =>
          friend =  @profileIndex?.by_github_id["#{user.userprofiles.github.id}"]
          if friend
            if not friend.clientid
              @signallingServer.send 'isonline',
                github: [user.userprofiles.github.id]
            _.extend friend.userprofiles.github, user.userprofiles.github
            friend.clientid = user.clientid
          @profileIndex.update @profileIndex.prep(friend)

When someone is offline, delete the clientid, this makes them un-callable. That
and their client id plenty well can change.

        @signallingServer.on 'offline', (user) =>
          _(@profileIndex.friends)
            .select (x) -> x.clientid is user.clientid
            .forEach (x) -> delete x.clientid

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

        @$.chat.addEventListener 'typing', _.debounce =>
          message =
            who: @userprofiles?.github?.name or @userprofiles?.github?.login or 'Anonymous'
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.send 'typing', message
        , 1000, leading: true

        @addEventListener 'typing', (evt) =>
          @$.chat.typerName = evt?.detail?.who

        @$.chat.addEventListener 'not-typing', =>
          message =
            who: @userprofiles?.github?.name or @userprofiles?.github?.login or 'Anonymous'
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.send 'not-typing', message

        @addEventListener 'not-typing', (evt) =>
          @$.chat.typerName = ""

