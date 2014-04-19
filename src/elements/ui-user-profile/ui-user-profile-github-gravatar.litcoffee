A user display image with a popup.

#Attributes
##github
This is an amalgamated profile object via OAuth sources.
##friends
This is a list of friends built up by inspecting your Github profile.

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
        if _.values(@friends).length
          return
        access_token = @github.access_token
        getSomeMembers = (org, done) =>
          org.nexturl =  org.nexturl or "https://api.github.com/orgs/#{org.login}/members?access_token=#{access_token}"
          mr = reqwest org.nexturl, (members) =>
            members = _.map members, (profile) ->
              userprofiles:
                github: profile
            members.forEach (member) =>
              if not @friends[member.userprofiles.github.id]
                @friends[member.userprofiles.github.id] = member
              else
                member = @friends[member.userprofiles.github.id]
              member.userprofiles.github.groups = member.userprofiles.github.groups or {}
              member.userprofiles.github.groups[org.login] = true
            link = mr.request.getResponseHeader("Link")
            if link
              org.nexturl = link.match(/\<(.+)\>; rel="next"/)?[1]
              if org.nexturl
                getSomeMembers org, done
              else
                done()
            else
              done()
        reqwest "https://api.github.com/user/orgs?access_token=#{access_token}", (orgs) =>
          async.each orgs, getSomeMembers, (err) =>
            if not err
              @fire 'newfriends', @friends
            else
              @fire 'error', err

      githubChanged: ->
        if @github
          @friends = @friends or {}
          bonzo(@).show()
          $(@$.gravatar).popup
            inline: true
            title: @github.name
            content: "@#{@github.login}"
            position: @tooltipPosition()
          @getFriends()
