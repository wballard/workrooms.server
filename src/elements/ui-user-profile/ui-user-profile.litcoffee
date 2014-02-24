A general purpose user profile display tile.

#Attributes
##profile
This is an amalgamated profile object via OAuth sources.

    require('../../elementmixin.litcoffee')

    Polymer 'ui-user-profile',
      attached: ->
        @showAnimated()

Click to dial anywhere on the row for now.

        @addEventListener 'click', =>
          @fire 'call',
            to: @profile.sessionid

      profileChanged: (oldValue, newValue) ->
        console.log 'profile', newValue
