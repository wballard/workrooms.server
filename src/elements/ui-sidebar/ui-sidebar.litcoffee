Sidebar, this is a nice place to hide controls out of the way.

    Polymer 'ui-sidebar',
      attached: ->
      toggle: ->
        if @visible
          @hideAnimated()
        else
          @showAnimated()
