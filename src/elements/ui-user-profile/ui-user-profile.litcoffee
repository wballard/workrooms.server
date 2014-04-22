A general purpose user profile display tile.

#Attributes
##user
User, which is the normal set of `clientid` if logged in and `userprofiles`
hash along from OAuth

    require('../elementmixin.litcoffee')

    Polymer 'ui-user-profile',
      attached: ->
        @showAnimated()

Click to dial anywhere on the row for now.

        @addEventListener 'click', =>
          @fire 'call',
            to: @user.clientid
