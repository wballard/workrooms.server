Platform = require('polyfill-webcomponents')
mixin = require('./mixin.coffee')
github = require('./github-auth.js')

###
Sign in via GitHub. This will trigger an OAuth user authentication by
its mere presence, and then expose the user profile.

#Attributes
clientid: OAuth client id string
clientsecret: OAuth client secret string

#Properties
userProfile: becomes available after an authentication, and it is
  available via event

#Events
userprofile: fires when the user profile is available
error: when bad things happen
###

class GithubOAuth extends HTMLElement
  createdCallback: ->
  enteredViewCallback: =>
    github.login @getAttribute('clientid'), @getAttribute('clientsecret'), (error, info) =>
      if error
        @fire 'error', error
      else
        info.profile_source = 'github'
        @userProfile = info
        @fire 'userprofile', info

module.exports = document.register 'github-oauth',
  prototype: GithubOAuth.prototype
