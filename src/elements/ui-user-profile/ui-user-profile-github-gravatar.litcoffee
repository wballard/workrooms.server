A user display image with a popup.

#Attributes
##github
This is an amalgamated profile object via OAuth sources.

    bonzo = require('bonzo')
    require('../elementmixin.litcoffee')

    Polymer 'ui-user-profile-github-gravatar',
      attached: ->
      githubChanged: ->
        if @github
          bonzo(@).show()
          $(@$.gravatar).popup
            inline: true
            title: @github?.name
            content: "@#{@github?.login}"
            position: @tooltipPosition()
        else
          bonzo(@).hide()
