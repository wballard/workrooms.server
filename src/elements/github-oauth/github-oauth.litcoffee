Sign in via GitHub. This will trigger an OAuth user authentication by
its mere presence, and then expose the user profile.

#Attributes
##clientid
OAuth client id string
##clientsecret
OAuth client secret string
##userProfile
Becomes available after an authentication.

#Events
##userprofile
When the user profile is available from GitHub post OAuth.
##error
When bad things happen.

#Methods
##login
Call this to force the login sequence.

    github = require('./github-auth.js')
    _ = require('lodash')

    Polymer 'github-oauth',
      inProgress: false

Auto login on attach.

      attached: ->

The signallying server will validate any ouath client, so it is valid to cache
that information here -- skips a trip to the server and makes profiles live
through Chrome sessions.

        document.addEventListener 'valid', (evt) ->
          chrome.storage.local.set github: evt.detail.userprofiles.github
        chrome.storage.local.get 'github', (config) =>
          console.log 'loading github profile', config
          @userProfile = config.github

Log in by going to github.
As a happy privacy feature, the email is deleted here on your client and never
sent along to the signalling server.

      login: ->
        console.log 'log in to github', @
        if @userProfile
          @fire 'userprofile', @userProfile
        else if @inProgress
          return
        else
          @inProgress = true
          github.login @clientid, @clientsecret, (error, info) =>
            if error
              @inProgress = false
              @fire 'error', error
            else
              delete info.email
              @inProgress = false
              info.profile_source = 'github'
              @userProfile = info
              @fire 'userprofile', @userProfile

Login just straight calls, clearing the tokens out, no debounce, no gui.

      logout: ->
        chrome.storage.local.remove 'github', =>
          @userProfile = null
          github.logout()

