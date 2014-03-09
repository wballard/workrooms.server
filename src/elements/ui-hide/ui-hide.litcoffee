Hide if hidden.

    require('../elementmixin.litcoffee')

    Polymer 'ui-hide',
      hideChanged: ->
        console.log 'hide', @hide
        if @hide
          debugger
          @hideAnimated()
        else
          @showAnimated()
      showChanged: ->
        if @show
          @showAnimated()
        else
          @hideAnimated()
