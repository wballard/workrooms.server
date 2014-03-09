This is the application -- the background page that ties it all together.

Originally, this was in Polymer, but 0.2.0 broke custom element support in background pages
which in some sense it no big deal as this isn't really a 'page' at all. So -- code it is!

    config = require('../config.yaml')
    config = config[chrome.runtime.id] or config['default']
    serverConfig = null

    require('../scripts/chrome-devreloader.litcoffee')(config)
    ExtensionIcon = require('../scripts/extension-icon.litcoffee')
    ConferenceTab = require('../scripts/conference-tab.litcoffee')
    SignallingServer = require('../scripts/signalling-server.litcoffee')
    GitHub = require('../scripts/github-oauth.litcoffee')
    GravatarDetector = require('../scripts/gravatar-detector.litcoffee')
    ChromeEventEmitter = require('../scripts/chrome-event-emitter.litcoffee')

    _ = require('lodash')

    console.log 'starting application'

    icon = new ExtensionIcon()
    conferenceTab = new ConferenceTab()
    signallingServer = new SignallingServer(config)
    github = new GitHub()
    gravatars = new GravatarDetector()
    backgroundChannel = new ChromeEventEmitter('background')
    gravatarChannel = new ChromeEventEmitter('gravatar')
    conferenceChannel = new ChromeEventEmitter('conference')

Keep track of connected calls in this buffer.

    calls = []
    userprofiles = {}

##Signalling Server Messages

Hello from the server! Now it is time to register this client in order to
get the rest of the configuration.

    signallingServer.on 'hello', ->
      signallingServer.send 'register',
        runtime: chrome.runtime.id
        calls: calls
      icon.drawIcon calls

After we have registered, the server sends along a configuration, this is to
protect -- or really to be able to switch -- ids for OAuth and STUN/TURN.

    signallingServer.on 'configured', (config) ->
      serverConfig = config
      github.login(serverConfig.github)

When valid, let our GitHub auth know.

    signallingServer.on 'valid', ->
      github?.validated()

The server combines profile data into a unified set of userprofiles.

    signallingServer.on 'userprofiles', (data) ->
      userprofiles = data
      conferenceChannel.send 'userprofiles', userprofiles

##Github login / logout messages

When a profile comes in from github, send it along to the signalling server.

    github.on 'userprofile', (profile) ->
      signallingServer.send 'userprofile', profile

    icon.on 'showconferencetab', conferenceTab.show

##Gravatar Detection

    backgroundChannel.on 'isonline', (detail) ->
      signallingServer.send 'isonline', detail

    signallingServer.on 'online', (detail) ->
      gravatarChannel.send 'online', detail, true

    backgroundChannel.on 'login', ->
      github.login()

    backgroundChannel.on 'logout', ->
      userprofiles = {}
      conferenceChannel.send 'userprofiles', userprofiles
      github.logout()

##Call Tracking

    conferenceChannel.on 'calls', (calls) ->
      icon.drawIcon calls

    backgroundChannel.pipe 'call', signallingServer
    backgroundChannel.pipe 'hangup', signallingServer

    backgroundChannel.on 'getcalls', (detail) ->
      conferenceChannel.send 'calls', calls
      conferenceChannel.send 'userprofiles', userprofiles

    signallingServer.on 'hangup', (hangupCall) ->
        _.remove calls, (call) -> call.callid is hangupCall.callid
        conferenceChannel.send 'calls', calls

    signallingServer.on 'outboundcall', (detail) ->
      detail.config = serverConfig
      calls.push detail
      conferenceChannel.send 'calls', calls

    signallingServer.on 'inboundcall', (detail) ->
      detail.config = serverConfig
      calls.push detail
      conferenceChannel.send 'calls', calls
      if not conferenceTab.visible
        url = detail?.userprofiles?.github?.avatar_url
        callToast = webkitNotifications.createNotification url, 'Call From', detail.userprofiles.github.name
        callToast.onclick = =>
          conferenceTab.show()
        callToast.show()

    backgroundChannel.pipe 'ice', signallingServer
    signallingServer.pipe 'ice', conferenceChannel

    backgroundChannel.pipe 'offer', signallingServer
    signallingServer.pipe 'offer', conferenceChannel

    backgroundChannel.pipe 'answer', signallingServer
    signallingServer.pipe 'answer', conferenceChannel

##Search

    backgroundChannel.pipe 'autocomplete', signallingServer
    signallingServer.pipe 'autocomplete', conferenceChannel

##Hangup Tracking
Hangup handling, when this is coming in the background channel, that
is a signal to hang up all calls. When from the server, it is information to hang
up one call.

    backgroundChannel.on 'hangup', ->
      calls.forEach (call) =>
        signallingServer.send 'hangup', call

    signallingServer.on 'hangup', (hangupCall) ->
      _.remove calls, (call) -> call.callid is hangupCall.callid
      conferenceChannel.send 'calls', calls
