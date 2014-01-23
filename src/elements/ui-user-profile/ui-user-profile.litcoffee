A general purpose user profile display tile.

#Attributes
##profile
This is an amalgamated profile object via OAuth sources.

    uuid = require('node-uuid')

    Polymer 'ui-user-profile',
      attached: ->

Click to dial anywhere on the row for now.

        @addEventListener 'click', =>
          @fire 'call',
            callid: uuid.v1()
            to:
              gravatar: @profile.github.gravatar_id

      profileChanged: (oldValue, newValue) ->
        console.log 'profile', newValue
