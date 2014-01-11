Platform = require('polyfill-webcomponents')
mixin = require('../mixin.coffee')

###
A simple action tool that will fire off an event when clicked.

# HTML Attributes
action: string name of event that will be fired on click
icon: put your font awesome styles here to have an icon
###
class UIVideoTool extends HTMLElement
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
      <a class="item">
        <i class="fa #{@getAttribute('icon')}"></i>
      </a>
    """
  enteredViewCallback: =>
    @addEventListener 'click', (evt) =>
      @fire @getAttribute('action')

###
An on/off toggle button.

# HTML Attributes
action: string name of event that will be fired on change event will
  be action.on or action.off depending on the state
icon: put your font awesome styles here to have an icon
active: true or false, indicating the state -- default false
###
class UIVideoToggle extends HTMLElement
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
      <a class="item">
        <i class="fa #{@getAttribute('icon')}"></i>
      </a>
    """
    @defineCustomElementProperty 'active'
  enteredViewCallback: =>
    @addEventListener 'click', (evt) =>
      if @active is 'true'
        @active = false
      else
        @active = true
  attributeChangedCallback: (name, oldValue, newValue) =>
    if name is 'active'
      if newValue is 'true'
        @$('a', @shadow).addClass('active')
        @fire "#{@getAttribute('action')}.on"
      else
        @$('a', @shadow).removeClass('active')
        @fire "#{@getAttribute('action')}.off"

###
Standard toolbar for video controls.
###
class UIVideoToolBar extends HTMLElement
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
    <div class="ui menu inverted">
      <content></content>
    </div>
    """
  enteredViewCallback: =>

module.exports =
  UIVideoToolBar: document.register 'ui-video-toolbar', prototype: UIVideoToolBar.prototype
  UIVideoTool: document.register 'ui-video-tool', prototype: UIVideoTool.prototype
  UIVideoToggle: document.register 'ui-video-toggle', prototype: UIVideoToggle.prototype
