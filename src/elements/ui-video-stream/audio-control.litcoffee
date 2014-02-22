This is a non visual element that listens for
`audio.on` and `audio.off` and `stream` events and then mutes
or unmutes said stream for you.

Not clear that this really warrants being its own component.

    Polymer 'audio-control',
      attached: ->
        @addEventListener 'stream', (evt) =>
          @stream = evt.detail
        @addEventListener 'audio.on', (evt) =>
          console.log 'unmute'
          @stream?.getAudioTracks()?.forEach (x) -> x.enabled = true
        @addEventListener 'audio.off', (evt) =>
          console.log 'mute'
          @stream?.getAudioTracks()?.forEach (x) -> x.enabled = false
