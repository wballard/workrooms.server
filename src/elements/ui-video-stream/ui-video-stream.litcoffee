Show a video stream with user interface.

#Attributes
##audio
##video
##mirror
##selfie
Mute the local audio output to avoid feedback.
##stream

    _ = require('lodash')
    require('../elementmixin.litcoffee')
    audioContext = require('../../scripts/web-audio.litcoffee').getContext()


    Polymer 'ui-video-stream',

      ready: ->
        @$.snapshot.hide()
        @$.sourcemutedaudio.hide()
        setInterval =>
          @takeSnapshot() if @video
        , 3000

Cool. Static snapshots to use when the video is muted. This gets defined when
the video plays.

      takeSnapshot: ->
        width = parseInt(getComputedStyle(@$.video).getPropertyValue('width').replace('px',''))
        height = parseInt(getComputedStyle(@$.video).getPropertyValue('height').replace('px',''))
        @$.takesnapshot.setAttribute('width', width)
        @$.takesnapshot.setAttribute('height', height)
        try
          ctx = @$.takesnapshot.getContext('2d')
          ctx.drawImage(@$.video, 0, 0, width, height)
          @$.snapshot.setAttribute('src', @$.takesnapshot.toDataURL('image/png'))
        catch error
          console.log error, width, height

Looking for attributes to mute. This is a neat trick as these are attributes
that trigger by presence, so we can hit them with the ?

      audioChanged: ->
        if @audio
          @$.sourcemutedaudio.hide()
        else
          @$.sourcemutedaudio.show()

      videoChanged: ->
        if @video
          @$.snapshot.hideAnimated =>
            @$.video.showAnimated()
        else
          @$.video.hideAnimated =>
            @$.snapshot.showAnimated()

      streamChanged: ->
        if @hasAttribute('selfie')
          @$.video.setAttribute('muted', '')
        else
          @$.video.removeAttribute('muted')
        if @hasAttribute('mirror')
          @$.video.classList.add 'mirror'
          @$.snapshot.classList.add 'mirror'
        if @stream
          @$.video.src = URL.createObjectURL(@stream)


We'll try manipulating the audio stream here rather than on the ui-video-call

          remoteStream = audioContext.createMediaStreamSource(@stream)

          console.log "Stream source from", remoteStream, @stream
          @lowPassFilter = audioContext.createBiquadFilter()
          @lowPassFilter.type = @lowPassFilter.LOWPASS
          @lowPassFilter.frequency.value = 10

Connect the nodes to create the filtered audio 

          remoteStream.connect(@lowPassFilter)
          @lowPassFilter.connect(audioContext.destination)

          @$.video.play()


          #@$.video.muted = true
          @$.loading.hide()
          @takeSnapshot()
        else
          @$.video.src = ''
          @$.loading.show()
