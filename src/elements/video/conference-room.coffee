###
Conference is an element that works a lot like a controller in other framerworks,
containting and coordinating other elements.

The basic idea here is to see if the entire notion of controllers can be tossed
if it is easy enough to just make a containing element.
###

Platform = require('polyfill-webcomponents')
#other custom elements at least need to be loaded and registered
require('./local-video.coffee')
require('../github-oauth.coffee')
require('./outbound-video-call.coffee')
require('./inbound-video-call.coffee')
mixin = require('../mixin.coffee')
uuid = require('node-uuid')

###
A `ConferenceRoom` brings together multiple video stream elements, giving you
a place to collaborate. The main benefit is that the conference room will deal
with `RTCPeerConnection` negotiation and signalling by talking to a web
socket based signalling server for you.

#HTML Attributes
server: websocket url pointing to the signalling server

#Methods
call(identifier): lets you call someone by an identifier
  currently this identifier is an object that allows multiple properties:
  - email
  - gravatar
###
class ConferenceRoom extends HTMLElement
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
    <github-oauth clientid="eda98e0fee66b8573312" clientsecret="8dc00cee1647aab2a2e926bf45914759e26f7632"></github-oauth>
    <span class="calls">
      <local-video></local-video>
    </span>
    """
    #keep track of user profiles from OAuth partners here
    @userprofiles = {}
  enteredViewCallback: =>
    #using a websocket to talk to the signalling server via peer identified
    #JSON messages
    @setAttribute('sessionid', uuid.v1())
    socket = new WebSocket(@getAttribute('server'))
    @signalling = signalling = (message) =>
      message.sessionid = @getAttribute('sessionid')
      socket.send(JSON.stringify(message))
    #handle all the messages back from the signalling server here
    socket.onmessage = (evt) =>
      try
        message = JSON.parse(evt.data)
        if message.inboundcall?
          @fire 'inboundcall', message
        if message.outboundcall?
          @fire 'outboundcall', message
        #forward signal messages along to the video elements and give them a chance
        #to process, assuming they 'match' at all
        forMe = (call) ->
          message.callid is call.getAttribute('callid') and message.peerid isnt call.getAttribute('peerid')
        @shadow.querySelectorAll('inbound-video-call').forEach (call) ->
          call.signal(message) if forMe(call)
        @shadow.querySelectorAll('outbound-video-call').forEach (call) ->
          call.signal(message) if forMe(call)
      catch err
        @fire 'error', error: err
    #all the webrtc process relies on their being a local video stream
    @addEventListener 'localvideostream', (evt) =>
      @shadow.querySelectorAll('outbound-video-call').forEach (outbound) =>
        outbound.localStream evt.detail.stream
      @shadow.querySelectorAll('inbound-video-call').forEach (inbound) =>
        inbound.localStream evt.detail.stream
      #hook up to chrome now that we have video and can be useful
      #there are two possible states -- we were already running this tab
      #and the tab was asynchronously launched by a call request, so
      #we'll deal with it by asking to dequeue if we see a call and
      #when we 'start up' video
      if not @_connected_to_chrome
        chrome.runtime.onMessage.addListener (message, sender, respond) =>
          if message.call
            chrome.runtime.sendMessage
              dequeueCalls: true
          if message.makeCalls
            message.makeCalls.forEach (x) => @call(x)
        @_connected_to_chrome = true
      chrome.runtime.sendMessage
        dequeueCalls: true
    #relay signal control through to the server
    @addEventListener 'signal', (evt) =>
      signalling evt.detail
    #an SSO system provided a profile, send it along to the server in order to
    #build up a directory
    @addEventListener 'userprofile', (evt) ->
      @userprofiles[evt.detail.profile_source] = evt.detail
      signalling userprofiles: @userprofiles
      #test hack to call yourself
      @call(email: evt.detail.email)
    #you are calling, set up an outbound call element to send it
    @addEventListener 'outboundcall', (evt) ->
      @$('.calls', @shadow)
        .append("""<outbound-video-call callid="#{evt.detail.callid}"></outbound-video-call>""")
    #someone called out, set up an inbound call element to receive it
    @addEventListener 'inboundcall', (evt) ->
      @$('.calls', @shadow)
        .append("""<inbound-video-call callid="#{evt.detail.callid}"></inbound-video-call>""")
    #video streams show up asynchronously, so supply calls peers -- both
    #inbound and outbound -- with the local video so it can share it
    @addEventListener 'needlocalstream', (evt) ->
      evt.detail.localStream(@shadow
        .querySelector('local-video')
        .stream
      )
    #signal every outbound call that we are muted, so all peer inbound calls
    #will get the signal and indicate mute
    @addEventListener 'audio.on', (evt) ->
      @$('outbound-video-call', @shadow).each (call) ->
        signalling
          sourcemutedaudio: false
          callid: call.getAttribute('callid')
          peerid: call.getAttribute('peerid')
    @addEventListener 'audio.off', (evt) ->
      @$('outbound-video-call', @shadow).each (call) ->
        signalling
          sourcemutedaudio: true
          callid: call.getAttribute('callid')
          peerid: call.getAttribute('peerid')
    @addEventListener 'video.on', (evt) ->
      @$('outbound-video-call', @shadow).each (call) ->
        signalling
          sourcemutedvideo: false
          callid: call.getAttribute('callid')
          peerid: call.getAttribute('peerid')
    @addEventListener 'video.off', (evt) ->
      @$('outbound-video-call', @shadow).each (call) ->
        signalling
          sourcemutedvideo: true
          callid: call.getAttribute('callid')
          peerid: call.getAttribute('peerid')
    #goodbye -- clean out the UI elements
    @addEventListener 'hangup', (evt) =>
      @$("outbound-video-call[callid='#{evt.detail.callid}'", @shadow).remove()
      @$("inbound-video-call[callid='#{evt.detail.callid}'", @shadow).remove()
    #keep alive, as well as presence -- this keeps the WebSocket up with
    #nginx in front, keeps the server refreshed
    setInterval ->
      signalling userprofiles: @userprofiles
    , 30 * 1000
  #the per call message exchange goes like this
  # connecting:
  #   (call) -> server
  #   calling client <- (outboundcall | notavailable)
  #   called client <- (inboundcall)
  # connected:
  #   (mute | unmute | hangup) -> server
  #   any client <- (mute | unmute | hangup)
  #
  # All calls have a .id which is unique to each call, and is used
  # as the correlation key between the inbound and outbound side
  # to set up peer-peer traffic
  call: (identifier) =>
    @signalling
      call: true
      to: identifier
      callid: uuid.v1()

module.exports =
  ConferenceRoom: document.register 'conference-room', prototype: ConferenceRoom.prototype
