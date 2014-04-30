A simple set of tools to manage the audio settings 

#Attributes
##onchange
This is the name of an event to fire when items are changed.


    Polymer 'ui-audio-controls',
      href: ''
      changed: ->
        if @onchange
          @fire @onchange, 
            volume: @$.volume.value
            filter: @$.filter.value