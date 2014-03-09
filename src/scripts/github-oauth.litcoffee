Sign in via GitHub. This will trigger an OAuth user authentication by
its mere presence, and then expose the user profile via event.

#Events
##userprofile
Fired with an object as detail that is the OAuth profile, minus email address


    github = require('./github-auth.js')
    _ = require('lodash')
    EventEmitter = require('events').EventEmitter

    module.exports =
      class GitHub extends EventEmitter
        config: {}
        inProgress: false
        userProfile: null

Log in by going to github.  As a happy privacy feature, the email is deleted
here on your client and never sent along to the signalling server.

        login: (config) ->
          @config = config or @config
          console.log 'log in to github'
          if @userProfile
            @emit 'userprofile', @userProfile
          else if @inProgress
            return
          else
            @inProgress = true
            chrome.storage.local.get 'github', (store) =>
              if store?.github?.id
                @userProfile = store.github
                @emit 'userprofile', @userProfile
                @inProgress = false
              else
                github.login @config.clientid, @config.clientsecret, (error, info) =>
                  if error
                    @inProgress = false
                    @emit 'error', error
                  else
                    delete info.email
                    @inProgress = false
                    info.profile_source = 'github'
                    @userProfile = info
                    @emit 'userprofile', @userProfile

Login just straight calls, clearing the tokens out, no debounce, no gui.

        logout: ->
          @userProfile = null
          chrome.storage.local.set github: @userProfile, =>
            github.logout()

When validated by the server, doing the OAuth background check of the token,
go ahead and store the profile.

        validated: ->
          chrome.storage.local.set github: @userProfile
