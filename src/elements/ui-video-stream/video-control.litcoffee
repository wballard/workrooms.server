This is a non visual element that listens for
`audio.on` and `audio.off` and `stream` events and then mutes
or unmutes said stream for you.

Not clear that this really warrants being its own component.

    Polymer 'video-control',
      attached: ->
        @addEventListener 'playerready', (evt) =>
          console.log 'player', evt.detail
          @player = evt.detail
        @addEventListener 'stream', (evt) =>
          @stream = evt.detail
        @addEventListener 'video.on', (evt) =>
          @stream?.getVideoTracks()?.forEach (x) -> x.enabled = true
          @player?.removeAttribute('sourcemutedvideo')
        @addEventListener 'video.off', (evt) =>
          @stream?.getVideoTracks()?.forEach (x) -> x.enabled = false
          @player?.setAttribute('sourcemutedvideo')
