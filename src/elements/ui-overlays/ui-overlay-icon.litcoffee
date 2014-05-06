An overlay of a font-awesome icon.
#Attributes
##icon
Name that icon `fa-` and all.

    require '../elementmixin.litcoffee'

    Polymer 'ui-overlay-icon',
      visibleChanged: ->
        if @visible
          @$.overlay.showAnimated()
        else
          @$.overlay.hideAnimated()
