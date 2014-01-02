###
This is a mixin method that adds utilities directly to a custom element, just
call it inside of `createdCallback(this)` and the methods will be attached.
###
bean = require('bean')
bonzo = require('bonzo')
bonzo = require('bonzo')

#Patch NodeList to be useful like an Array
arrayMethods = Object.getOwnPropertyNames(Array.prototype)
arrayMethods.forEach (methodName) ->
  NodeList.prototype[methodName] = Array.prototype[methodName]

###
Pull in methods from bonzo as single actions.
###
Element.prototype.appendHtml = (html) ->
  bonzo(this).append(html).get(0)

Element.prototype.before = (html) ->
  bonzo(this).before(html).get(0)

Element.prototype.after = (html) ->
  bonzo(this).after(html).get(0)

Element.prototype.previous = () ->
  bonzo(this).previous().get(0)

Element.prototype.next = () ->
  bonzo(this).next().get(0)

Element.prototype.parent = () ->
  bonzo(this).parent().get(0)

Element.prototype.addClass = (style) ->
  bonzo(this).addClass(style).get(0)

Element.prototype.hasClass = (style) ->
  bonzo(this).hasClass(style)

Element.prototype.replaceWith = (html) ->
  bonzo(this).replaceWith(html).get(0)

Element.prototype.css = (object) ->
  bonzo(this).css(object).get(0)

###
Macro to define a property that will fire off the `attributeChangedCallback`
as defined in WebComponents.
###
Element.prototype.defineCustomElementProperty = (name) ->
  object = this
  Object.defineProperty object, name,
    get: -> object.getAttribute(name)
    set: (value) -> object.setAttribute(name, value)
    configurable: true
    enumerable: true
###
Fire off a custom event with the supplied detail. This is a full on bubbling
DOM event.
###
Element.prototype.fire = (name, data) ->
  this.dispatchEvent new CustomEvent(name,
    bubbles: true
    detail: data
  )
###
Node syntax event handling.
###
Element.prototype.on = (name, handler) ->
  bean.on this, name, handler
