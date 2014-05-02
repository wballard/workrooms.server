Sidebar, this is a nice place to hide controls out of the way.

    Polymer 'ui-sidebar',
      visibleChanged: ->
        if @visible
          @showAnimated()
        else
          @hideAnimated()
