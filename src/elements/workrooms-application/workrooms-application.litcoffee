This is the main application code. A bit different setup, using a custom
element as the application root, comparing this to using Angular.js it
seems like a good idea since there is just one 'scope tree' this way, the
DOM itself! And, just one event space, the DOM itself -- no need for the
separate event mechanisms of `$emit` and `$broadcast`.

#Attributes
##serverconfig
All the settings supplied through by the server.
##calls
Array of all active calls metadata. These aren't calls themselves, just
call metadata used to generate actual calls between peers.

Store configurations for each runtime id along with the code.

    _ = require('lodash')
    config = require('../../config.yaml')
    config = config[chrome.runtime.id] or config['default']

    Polymer 'workrooms-application',
      calls: []
      screenshares: []
      userprofiles: {}

This is the magic part, set config and watch the data binding fill in the
elements that actually do work!

      ready: ->
        console.log 'application starting', config
        @config = config

      attached: ->

When we have a connection to this, the background page, connect through to
the conference tab port.

        @addEventListener 'chromeconnect', (evt) =>
          if evt.detail.name is 'background'
            @$.conference.connect()

        @addEventListener 'calls', (evt) =>
          @$.icon.drawIcon(@calls)

        @addEventListener 'getcalls', (evt) =>
          @$.conference.relay 'calls', @calls

When the server says hello, tell it about the local calls we may already have.
This lets the server live through a crash by having all the clients keep it
up to date.

        @addEventListener 'hello', =>
          setTimeout =>
            @$.icon.drawIcon(@calls)
          , 1500
          @$.github.fire 'register',
            runtime: chrome.runtime.id
            calls: @calls
          @$.conference.relay 'calls', @calls

Once you have registered with the server, the configuration will come.

        @addEventListener 'configured', (evt) =>
          @serverconfig = evt.detail
          @$.github.login()
          @$.icon.drawIcon()
          window.debugCallSelf = =>
            @$.server.relay 'call', to: evt.detail.sessionid
          window.debugCallFail = =>
            @$.server.relay 'call', to: 'fail'

Keep track of all userprofiles for the current user.

        @addEventListener 'userprofiles', (evt) =>
          @userprofiles = evt.detail
        @addEventListener 'getuserprofiles', =>
          @$.conference.relay 'userprofiles', @userprofiles

Track inbound and outbound calls when asked into the local calls array.

        @addEventListener 'outboundcall', (evt) =>
          evt.detail.config = @serverconfig
          if not @$.tab.visible?
            @$.icon.fire 'showconferencetab'
          @calls.push evt.detail
          @$.conference.relay 'calls', @calls

        @addEventListener 'inboundcall', (evt) =>
          evt.detail.config = @serverconfig
          if not @$.tab.visible?
            url = evt?.detail?.userprofiles?.github?.avatar_url
            callToast = webkitNotifications.createNotification url, 'Call From', evt.detail.userprofiles.github.name
            callToast.onclick = =>
              @$.icon.fire 'showconferencetab'
            callToast.show()
          @calls.push evt.detail
          @$.conference.relay 'calls', @calls

        @addEventListener 'outboundscreen', (evt) =>
          evt.detail.config = @serverconfig
          @screenshares.push evt.detail

        @addEventListener 'inboundscreen', (evt) =>
          evt.detail.config = @serverconfig
          @screenshares.push evt.detail

        @$.background.addEventListener 'hangup', (evt) =>
          evt.stopPropagation()
          @calls.concat(@screenshares).forEach (call) =>
            @$.server.relay 'hangup', call

        @addEventListener 'hangup', (evt) =>
          if evt.detail
            hangupCall = evt.detail
            _.remove @calls, (call) -> call.callid is hangupCall.callid
            _.remove @screenshares, (call) -> call.callid is hangupCall.callid
            console.log 'remaining', @calls, @screenshares
            @$.conference.relay 'calls', @calls

        @addEventListener 'hangupscreenshare', (evt) =>
          @$.server.relay 'hangup', evt.detail
