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
      audioChanged: ->
        if @stream
          @stream?.getAudioTracks()?.forEach (x) => x.enabled = @audio

Toggle the stream to truly mute the video signal. When disabling, put in a
delay so that on the far side, animation has time to switch over to a muted
image. There is no need to do this when turning it back on as the mute image
already has the video covered and will fade away on the far side.

      videoChanged: ->
        delay = 1000 if not @video
        if @stream
          setTimeout =>
            @stream?.getVideoTracks()?.forEach (x) => x.enabled = @video
          , delay
      attached: ->
        mediaConstraints =
          video:
            mandatory:
              maxWidth: 640
              maxHeight: 480
          audio: true
        getUserMedia mediaConstraints, (err, stream) =>
          if err
            @fire 'error', err
          else

We need to filter the audio to make it a bit more easy on the ears
so we'll get a MediaStream source that we can manipulate with the Web Audio api

            source = audioContext.createMediaStreamSource(stream)
            destination = audioContext.createMediaStreamDestination()
            lowPassFilter = audioContext.createBiquadFilter()
            lowPassFilter.type = lowPassFilter.LOWPASS
            lowPassFilter.frequency.value = 250
            gainFilter = audioContext.createGain()

            source.connect lowPassFilter
            lowPassFilter.connect destination

Pull the original stream's audio and replace it with the audio from the filtered stream

            console.log "Stream audio tracks originally:", stream.getAudioTracks()[0].id

            #stream.removeTrack(stream.getAudioTracks()[0])
            #stream.addTrack(destination.stream.getAudioTracks()[0])

            console.log "Stream audio tracks now set up to:", stream.getAudioTracks()[0].id

Some temporary(?) helpers for adjusting the audio filtering properties while we test

            window._audio = 
              low: lowPassFilter.frequency
              gain: gainFilter.gain

            @stream = stream
