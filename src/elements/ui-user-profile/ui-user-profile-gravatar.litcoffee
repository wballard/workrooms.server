A user display image with a popup.

#Attributes
##userprofiles
This is an amalgamated profile object via OAuth sources.

    bonzo = require('bonzo')
    require('../elementmixin.litcoffee')

    Polymer 'ui-user-profile-gravatar',
      userprofilesChanged: (oldValue, newValue) ->
        if oldValue?.github?.name isnt newValue?.github?.name
          bonzo(@).show()
          $(@$.gravatar).popup
            inline: true
            title: @userprofiles.github.name
            content: "@#{@userprofiles.github.login}"
