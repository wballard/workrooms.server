Show a video stream with user interface.

#Attributes
##mirror
Backward video. Looks like a mirror.
##selfie
Mute the local audio output to avoid feedback.
##snapshot
Encoded snapshot as a data-url, allowing easy text transport.
##stream
Live video stream will be played.

#Events
##snapshot
Fired when a fresh snapshot is taken.
##sized
Fired when the video is sized. Use this to control zoom levels to prevent
pixellation.

    _ = require 'lodash'
    bonzo = require 'bonzo'
    require './elementmixin.litcoffee'
    audio = require './scripts/web-audio.litcoffee'
    audioContext = audio.getContext()

    Polymer 'ui-video-stream',

Clean up polling loops.

      detached: ->
        clearInterval @volumePoller

Startup audio to let you know a call is coming in.

      attached: ->
        if !@hasAttribute 'selfie'
          audio.playSound 'media/startup.ogg'
          window.focus()

Snapshot on play.

        @$.video.addEventListener 'canplay', =>
          @takeSnapshot()
          @videoSize =
            width: @$.video.videoWidth
            height: @$.video.videoHeight
          @fire 'videoplay'

Cool. Static snapshots to use when the video is muted.

      takeSnapshot: ->
        width = parseInt(getComputedStyle(@$.video).getPropertyValue('width').replace('px',''))
        height = parseInt(getComputedStyle(@$.video).getPropertyValue('height').replace('px',''))
        @$.takesnapshot.setAttribute('width', width)
        @$.takesnapshot.setAttribute('height', height)
        try
          ctx = @$.takesnapshot.getContext('2d')
          ctx.drawImage(@$.video, 0, 0, width, height)
          @snapshot = @$.takesnapshot.toDataURL('image/png')
        catch error
          console.log error, width, height

      snapshotChanged: (oldValue, newValue) ->
        if newValue isnt oldValue
          @fire 'snapshot', @snapshot

Play the video stream. This mutes local audio if it is a `selfie`, otherwise
the feedback would be brutal. Mirroing is available too, folks are used
to seeing themselves in a mirror -- backwards.

This installs a band pass filter in a valiant attempt to cut out background
noise.

      streamChanged: ->
        @$.video.setAttribute 'muted', ''

        if @hasAttribute('mirror')
          @$.video.classList.add 'mirror'

        if @stream
          source = audioContext.createMediaStreamSource(@stream)
          console.log source, @stream.getAudioTracks()
          highPitchedHumans = 3000
          lowPitchedHumans = 50
          humanSpeechCenter = (highPitchedHumans + lowPitchedHumans) / 2
          filter = audioContext.createBiquadFilter()
          filter.type = filter.BANDPASS
          filter.frequency.value = humanSpeechCenter
          filter.Q = humanSpeechCenter / (highPitchedHumans - lowPitchedHumans)
          analyser = audioContext.createAnalyser()
          analyser.smoothingTimeConstant = 0.5
          fftBins = new Float32Array(analyser.fftSize)
          @talking = false
          @volumePoller = setInterval =>
            analyser.getFloatFrequencyData(fftBins)
            maxGain = _(fftBins)
              .select (x) -> x < 0
              .max()
              .value()
            if maxGain > -65
              @talking = true
            else
              @talking = false
          , 100
          source.disconnect()
          source.connect filter
          filter.connect analyser
          analyser.connect audioContext.destination
          @$.video.classList.remove 'placeholder'
          @$.video.src = URL.createObjectURL(@stream)
          @$.video.play()
        else
          @$.video.classList.add 'placeholder'
          @$.video.src = ''
