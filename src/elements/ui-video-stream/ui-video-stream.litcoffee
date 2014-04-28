Show a video stream with user interface.

#Attributes
##audio
##video
##mirror
##mutedaudio
##stream

    _ = require('lodash')
    bonzo = require('bonzo')
    morpheus = require('morpheus')

    Polymer 'ui-video-stream',

      ready: ->
        bonzo(@$.snapshot).hide()
        bonzo(@$.sourcemutedaudio).hide()

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
          bonzo(@$.sourcemutedaudio).hide()
        else
          bonzo(@$.sourcemutedaudio).show()

      videoChanged: ->
        if @video
          @$.video.showAnimated()
          @$.snapshot.hideAnimated()
        else
          @$.video.hideAnimated()
          @$.snapshot.showAnimated()

      streamChanged: ->
        if @hasAttribute('mutedaudio')
          @$.video.setAttribute('muted', '')
        else
          @$.video.removeAttribute('muted')
        if @hasAttribute('mirror')
          bonzo(@$.video)
           .css('-webkit-transform', 'scaleX(-1)')
          bonzo(@$.snapshot)
           .css('-webkit-transform', 'scaleX(-1)')
        if @stream
          @$.video.src = URL.createObjectURL(@stream)
          @$.video.play()
          bonzo(@$.loading).hide()
        else
          @$.video.src = ''
          bonzo(@$.loading).show()
