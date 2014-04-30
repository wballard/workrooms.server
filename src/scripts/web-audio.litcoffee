Singleton as we only need a single audio context for the application
and using multiple contexts is generally considered inefficient

    window._activeAudioContext = null
    
    module.exports = {
      getContext: ->
        return window._activeAudioContext if window._activeAudioContext?
        window._activeAudioContext = new window.webkitAudioContext()
        return window._activeAudioContext
    }