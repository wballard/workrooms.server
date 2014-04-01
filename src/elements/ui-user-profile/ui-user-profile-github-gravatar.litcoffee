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
          github = @github
          bonzo(@).show()
          $(@$.gravatar).popup
            inline: true
            title: @github.name
            content: "@#{@github.login}"
            position: @tooltipPosition()
          access_token = @github.access_token
          reqwest "https://api.github.com/user/orgs?access_token=#{access_token}", (orgs) =>
            async.map orgs, (org, callback) =>
              reqwest "https://api.github.com/orgs/#{org.login}/members?access_token=#{access_token}", (members) =>
                callback null, members
            , (err, results) =>
              console.log(err) if err
              results = _(results)
                .flatten()
                .sortBy (x) -> (x.name or x.login or '').toLowerCase()
                .uniq (x) -> x.name or x.login
                .value()
              github.friends = _.map results, (profile) ->
                userprofiles:
                  github: profile
              @fire 'friends', results
        else
          bonzo(@).hide()
