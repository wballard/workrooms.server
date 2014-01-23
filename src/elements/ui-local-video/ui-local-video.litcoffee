#Overview
A local video stream is designed to show you yourself. It is a simply styled
player with video and audio mute controls.

    Polymer 'ui-local-video',
      streamChanged: (oldValue, newValue) ->
        @$.player.display(newValue)
