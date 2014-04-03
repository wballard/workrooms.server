A user display image with a popup.

#Attributes
##github
This is an amalgamated profile object via OAuth sources.

    bonzo = require('bonzo')
    require('../elementmixin.litcoffee')
    reqwest = require('reqwest')
    async = require('async')
    _ = require('lodash')

    Polymer 'ui-user-profile-github-gravatar',
      attached: ->

Use the GitHub API to get all of your organizations, this forms your friend
list.

      githubChanged: ->
        if @github
          @github.friends = []
          bonzo(@).show()
          $(@$.gravatar).popup
            inline: true
            title: @github.name
            content: "@#{@github.login}"
            position: @tooltipPosition()
          access_token = @github.access_token
          getSomeMembers = (url) =>
            if url
              mr = reqwest url, (members) =>
                link = mr.request.getResponseHeader("Link")
                if link
                  nextPage = link.match(/\<(.+)\>; rel="next"/)?[1]
                  getSomeMembers nextPage
                members = _.map members, (profile) ->
                  userprofiles:
                    github: profile
                buffer = @github.friends.concat members
                nameO = (x) ->
                  x.userprofiles.github.name or x.userprofiles.github.login
                @github.friends = _(buffer)
                  .sortBy (x) -> nameO(x).toLowerCase()
                  .uniq (x) -> nameO(x)
                  .value()
                @fire 'friends', @github.friends
          reqwest "https://api.github.com/user/orgs?access_token=#{access_token}", (orgs) =>
            orgs.forEach (org) ->
              firstMembers = "https://api.github.com/orgs/#{org.login}/members?access_token=#{access_token}"
              getSomeMembers firstMembers
        else
          bonzo(@).hide()
