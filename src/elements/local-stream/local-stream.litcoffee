This element is a bit of an adapter to turn the API oriented local stream
into a DOM element, all Polymer style...

#Attributes
##stream
This is the actual stream object, which will have video and audio.
##video
If present, use the camera.
##audio
If present, use the microphone.

#Events
##error
Bad stuff. Fires.
##localstream
Fires when a stream is available, also after then `stream` property is set.

    getUserMedia = require('getusermedia')
    audioContext = require('../../scripts/web-audio.litcoffee').getContext()


    Polymer 'local-stream',
      attached: ->
        mediaConstraints =
          video:
            mandatory:
              maxWidth: 640
              maxHeight: 480
          audio: @hasAttribute('audio')
        getUserMedia mediaConstraints, (err, stream) =>
          if err
            @fire 'error', err
          else
            @stream = stream

We'll try manipulating the audio stream here rather than on the ui-video-call

            streamSource = audioContext.createMediaStreamSource(@stream)

            @lowPassFilter = audioContext.createBiquadFilter()
            @lowPassFilter.type = @lowPassFilter.LOWPASS
            @lowPassFilter.frequency.value = 1000

            @highPassFilter = audioContext.createBiquadFilter()
            @highPassFilter.type = @lowPassFilter.HIGHPASS
            @highPassFilter.frequency.value = 30

            gainNode = audioContext.createGain()

For now expose these to the debug console, TODO: remove later

            window._lowPass = @lowPassFilter
            window._highPass = @highPassFilter
            window._gain = gainNode
            
            window._setFrequencyFilters = (low=30,high=1000) ->
              window._lowPass.frequency.value = high
              window._highPass.frequency.value = low


Connect the nodes to create the filtered audio 
            
            streamSource.connect gainNode
            gainNode.connect @highPassFilter
            @highPassFilter.connect @lowPassFilter
            @lowPassFilter.connect(audioContext.destination)

