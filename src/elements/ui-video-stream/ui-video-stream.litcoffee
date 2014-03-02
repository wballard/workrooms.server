Show a video stream with user interface.

#Attributes
##audio
##video
##mirror
##mutedaudio
##stream

    _ = require('lodash')
    bonzo = require('bonzo')

    SNAPSHOT_TIMEOUT = 1 * 1000
    IN_EFFECT = "fadeIn"
    OUT_EFFECT = "fadeOut"

    Polymer 'ui-video-stream',

      ready: ->
        bonzo(@$.snapshot).hide()
        bonzo(@$.sourcemutedaudio).hide()

Cool. Static snapshots to use when the video is muted. This gets defined when
the video plays.

      attached: ->
        @$.video.addEventListener 'canplay', =>
          @fire 'snapshot'
        @addEventListener 'snapshot', =>
          width = parseInt(getComputedStyle(@$.video).getPropertyValue('width').replace('px',''))
          height = parseInt(getComputedStyle(@$.video).getPropertyValue('height').replace('px',''))
          @$.takesnapshot.setAttribute('width', width)
          @$.takesnapshot.setAttribute('height', height)
          takeSnapshot = =>
            width = parseInt(getComputedStyle(@$.video).getPropertyValue('width').replace('px',''))
            height = @$.video.videoHeight / (@$.video.videoWidth/width)
            ctx = @$.takesnapshot.getContext('2d')
            ctx.drawImage(@$.video, 0, 0, width, height)
            @$.snapshot.setAttribute('src', @$.takesnapshot.toDataURL('image/png'))
          takeSnapshot()
          setInterval =>
            if not @video is 'false'
              takeSnapshot()
          , SNAPSHOT_TIMEOUT

Looking for attributes to mute. This is a neat trick as these are attributes
that trigger by presence, so we can hit them with the ?

      audioChanged: ->
        if @audio
          bonzo(@$.sourcemutedaudio).hide()
        else
          bonzo(@$.sourcemutedaudio).show()

      videoChanged: ->
        if @video
          bonzo(@$.video).removeClass(OUT_EFFECT).addClass(IN_EFFECT).show()
          bonzo(@$.snapshot).removeClass(IN_EFFECT).addClass(OUT_EFFECT).hide()
        else
          bonzo(@$.video).removeClass(IN_EFFECT).addClass(OUT_EFFECT).hide()
          bonzo(@$.snapshot).removeClass(OUT_EFFECT).addClass(IN_EFFECT).show()

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
