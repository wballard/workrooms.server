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
      userprofiles: {}

This is the magic part, set config and watch the data binding fill in the
elements that actually do work!

      ready: ->
        console.log 'application starting', config
        @config = config

      attached: ->

        @addEventListener 'calls', (evt) =>
          @$.icon.drawIcon(@calls)

        @addEventListener 'getcalls', (evt) =>
          @$.local.relay 'calls', @calls

When the server says hello, tell it about the local calls we may already have.
This lets the server live through a crash by having all the clients keep it
up to date.

        @addEventListener 'hello', =>
          setTimeout =>
            @$.icon.drawIcon(@calls)
          , 1000
          @$.github.fire 'register',
            runtime: chrome.runtime.id
            calls: @calls
          @$.local.relay 'calls', @calls

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
          @$.local.relay 'userprofiles', @userprofiles

Track inbound and outbound calls when asked into the local calls array.

        @addEventListener 'outboundcall', (evt) =>
          evt.detail.config = @serverconfig
          @calls.push evt.detail
          @$.local.relay 'calls', @calls

        @addEventListener 'inboundcall', (evt) =>
          ###
          url = evt?.detail?.userprofiles?.github?.avatar_url
          callToast = webkitNotifications.createNotification url, 'Call From', evt.detail.userprofiles.github.name
          callToast.onclick = ->
            chrome.runtime.sendMessage
              showConferenceTab: true
          callToast.show()
          ###
          evt.detail.config = @serverconfig
          @calls.push evt.detail
          @$.local.relay 'calls', @calls

        @addEventListener 'hangup', (evt) =>
          console.log 'hangup', evt
          _.forEach evt?.detail?.calls or [], (hangupCall) =>
            _.remove @calls, (call) ->
              console.log 'hangup', call
              call.callid is hangupCall.callid
          @$.local.relay 'calls', @calls
