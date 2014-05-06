An overlay of any old image, use it to cover things.
#Attributes
##image
An image source url, a link or data -- I love those data urls.

    require '../elementmixin.litcoffee'

    Polymer 'ui-overlay-image',
      visibleChanged: ->
        if @visible
          @$.overlay.showAnimated()
        else
          @$.overlay.hideAnimated()
