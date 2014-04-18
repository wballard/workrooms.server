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
list. But only bother to load it if we haven't previously.

      getFriends: ->
        if _.values(@github.friends).length
          return
        access_token = @github.access_token
        getSomeMembers = (org, url) =>
          if url
            mr = reqwest url, (members) =>
              link = mr.request.getResponseHeader("Link")
              if link
                nextPage = link.match(/\<(.+)\>; rel="next"/)?[1]
                getSomeMembers org, nextPage
              members = _.map members, (profile) ->
                userprofiles:
                  github: profile
              members.forEach (member) =>
                member.userprofiles.github.groups = member.userprofiles.github.groups or {}
                if not @github.friends[member.userprofiles.github.id]
                  @github.friends[member.userprofiles.github.id] = member
                else
                  member = @github.friends[member.userprofiles.github.id]
                member.userprofiles.github.groups[org.login] = true
              @fire 'newfriends'
        reqwest "https://api.github.com/user/orgs?access_token=#{access_token}", (orgs) =>
          orgs.forEach (org) ->
            firstMembers = "https://api.github.com/orgs/#{org.login}/members?access_token=#{access_token}"
            getSomeMembers org, firstMembers

      githubChanged: ->
        if @github
          @github.friends = @github.friends or {}
          bonzo(@).show()
          $(@$.gravatar).popup
            inline: true
            title: @github.name
            content: "@#{@github.login}"
            position: @tooltipPosition()
          @getFriends()
