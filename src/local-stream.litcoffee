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

    getUserMedia = require 'getusermedia'
    audioContext = require('./scripts/web-audio.litcoffee').getContext()
    _ = require 'lodash'

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

#Polymer Lifecycle
On attach, grab access to the user camera so that we have a stream.

      attached: ->
        mediaConstraints =
          video:
            mandatory:
              maxWidth: 320
              maxHeight: 240
          audio: true
        getUserMedia mediaConstraints, (err, stream) =>
          if err
            console.log err
            @fire 'error', err
          else

We need to filter the audio to make it a bit more easy on the ears
so we'll get a MediaStream source that we can manipulate with the Web Audio API
and hook on some filters to human speech range.

            source = audioContext.createMediaStreamSource(stream)
            destination = audioContext.createMediaStreamDestination()

            highPitchedHumans = 880
            lowPitchedHumans = 50
            humanSpeechCenter = (highPitchedHumans + lowPitchedHumans) / 2
            filter = audioContext.createBiquadFilter()
            filter.type = filter.BANDPASS
            filter.frequency.value = humanSpeechCenter
            filter.Q = humanSpeechCenter / (highPitchedHumans - lowPitchedHumans)

And figure the gain. We'll use this to send an event that someone is talking.

            analyser = audioContext.createAnalyser()
            analyser.fftSize = 512
            analyser.smoothingTimeConstant = 0.5
            fftBins = new Float32Array(analyser.fftSize)
            @volumePoller = setInterval ->
              analyser.getFloatFrequencyData(fftBins)
              maxGain = _(fftBins)
                .select (x) -> x < 0
                .max()
                .value()
            , 100

Connect the streams.

            source.connect analyser
            analyser.connect destination

Pull the original stream's audio and replace it with the audio from the
filtered stream, so that we send a filtered stream. Only the audio we want
leaves the computer.

            console.log "Stream audio tracks originally:", stream.getAudioTracks()[0].id

            stream.removeTrack(stream.getAudioTracks()[0])
            stream.addTrack(destination.stream.getAudioTracks()[0])

            console.log "Stream audio tracks now set up to:", stream.getAudioTracks()[0].id
            @stream = stream

      detached: ->
        clearInterval @volumePoller
