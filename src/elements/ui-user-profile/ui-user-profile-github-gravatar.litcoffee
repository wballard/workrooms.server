A user display image with a popup.

#Attributes
##github
This is an amalgamated profile object via OAuth sources.

    Polymer 'ui-user-profile-github-gravatar',
      attached: ->
      githubChanged: ->
        $(@$.gravatar).popup
          inline: true
          title: @github?.name
          content: "@#{@github?.login}"
