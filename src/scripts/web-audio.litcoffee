Singleton as we only need a single audio context for the application
and using multiple contexts is generally considered inefficient

    window._activeAudioContext = null
    window._audioBuffer = {}

    loadSound = (path,cb) ->
      return cb(_audioBuffer[path]) if _audioBuffer[path]

      request = new XMLHttpRequest()
      request.open 'GET', path, true
      request.responseType = 'arraybuffer'
      context = getContext()
      request.onload = ->
        context.decodeAudioData request.response
          , (buffer) ->
            _audioBuffer[path] = buffer
            cb(buffer)
          , (err) ->
            console.error 'unable to load audio clip: #{path}'

      request.send()

    getContext = ->
        return window._activeAudioContext if window._activeAudioContext?
        window._activeAudioContext = new window.webkitAudioContext()
        return window._activeAudioContext

    module.exports =
      getContext: getContext
      playSound: (path) =>
        loadSound path, (buffer) =>
          context = getContext()
          source = context.createBufferSource()
          source.buffer = buffer
          source.connect context.destination
          source.start 0
