This is a non visual element that listens for
`audio.on` and `audio.off` and `stream` events and then mutes
or unmutes said stream for you.

Not clear that this really warrants being its own component.

    Polymer 'video-control',
      attached: ->
        @addEventListener 'playerready', (evt) =>
          @player = evt.detail
        @addEventListener 'stream', (evt) =>
          @stream = evt.detail
        @addEventListener 'video.on', (evt) =>
          @player?.removeAttribute('sourcemutedvideo')
          @stream?.getVideoTracks()?.forEach (x) -> x.enabled = true
        @addEventListener 'video.off', (evt) =>
          @player?.setAttribute('sourcemutedvideo')
          @stream?.getVideoTracks()?.forEach (x) -> x.enabled = false
