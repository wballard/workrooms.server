Sidebar, this is a nice place to hide controls out of the way.

    Polymer 'ui-sidebar',

jQuery can't seem to query the shadow DOM in here, so manual wrapping
of a selected element.

      attached: ->
        @sidebar = $(@$.sidebar).sidebar()

Hmm -- this feels a bit like layering and redundancy.

      toggle: ->
        @sidebar.sidebar('toggle')
