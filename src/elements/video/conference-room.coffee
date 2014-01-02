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
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = """
    <local-video></local-video>
    <github-oauth clientid="eda98e0fee66b8573312" clientsecret="8dc00cee1647aab2a2e926bf45914759e26f7632"></github-oauth>
    <section id="calls"></section>
    """
    #keep track of user profiles from OAuth partners here
    @userprofiles = {}
  enteredViewCallback: =>
    @setAttribute('sessionid', uuid.v1())
    socket = @socket = new WebSocket(@getAttribute('server'))
    signalling = @signalling = (message) =>
      message.sessionid = @getAttribute('sessionid')
      socket.send(JSON.stringify(message))
    socket.onmessage = (evt) =>
      try
        message = JSON.parse(evt.data)
        if message.inboundcall
          @fire 'inboundcall', message
        if message.outboundcall
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
    @on 'localvideostream', (evt) =>
      @shadow.querySelectorAll('outbound-video-call').forEach (outbound) =>
        outbound.localStream evt.detail.stream
      @shadow.querySelectorAll('inbound-video-call').forEach (inbound) =>
        inbound.localStream evt.detail.stream
      #hook up to chrome now that we have video and can be useful
      #there are two possible states -- we were already running this tab
      #and the tab was asynchronously launched by a call request, so
      #we'll deal with it by asking to dequeue if we see a call and
      #when we 'start up' video
      chrome.runtime.onMessage.addListener (message, sender, respond) =>
        if message.call
          chrome.runtime.sendMessage
            dequeueCalls: true
        if message.makeCalls
          message.makeCalls.forEach (x) => @call(x)
      chrome.runtime.sendMessage
        dequeueCalls: true
    @on 'ice', (evt) =>
      signalling evt.detail
    @on 'sdp', (evt) =>
      signalling evt.detail
    @on 'userprofile', (evt) ->
      @userprofiles[evt.detail.profile_source] = evt.detail
      signalling userprofiles: @userprofiles
      #test hack to call yourself
      @call(email: evt.detail.email)
    @on 'outboundcall', (evt) ->
      @shadow
        .querySelector('#calls')
        .appendHtml("""<outbound-video-call callid="#{evt.detail.callid}"></outbound-video-call>""")
    @on 'inboundcall', (evt) ->
      @shadow
        .querySelector('#calls')
        .appendHtml("""<inbound-video-call callid="#{evt.detail.callid}"></inbound-video-call>""")
    @on 'needlocalstream', (evt) ->
      evt.detail.localStream(@shadow
        .querySelector('local-video')
        .stream
      )
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
    console.log 'calling', identifier, @
    @signalling
      call: true
      to: identifier
      callid: uuid.v1()


module.exports =
  ConferenceRoom: document.register 'conference-room', prototype: ConferenceRoom.prototype
