A general purpose user profile display tile.

#Attributes
##showstatus
If set, show the status indicator lights.
##userprofiles
This is an amalgamated profile object via OAuth sources.
##clientid
Identifier, if set you can call this person.

    require('../elementmixin.litcoffee')

    Polymer 'ui-user-profile',
      attached: ->
        @showAnimated()

Click to dial anywhere on the row for now.

        @addEventListener 'click', =>
          @fire 'call',
            to: @clientid
