###
This is a mixin method that adds utilities directly to a custom elements.
###

bonzo = require('bonzo')
qwery = require('qwery')
_ = require('underscore')

Element.prototype.$ = (selector, target) ->
  bonzo(qwery(selector, target))

#Patch NodeList to be useful like an Array
arrayMethods = Object.getOwnPropertyNames(Array.prototype)
arrayMethods.forEach (methodName) ->
  NodeList.prototype[methodName] = Array.prototype[methodName]

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
  #and an intial firing
  object.attributeChangedCallback name, undefined, object.getAttribute(name)

###
Fire off a custom event with the supplied detail. This is a full on bubbling
DOM event.
###
Element.prototype.fire = (name, data) ->
  this.dispatchEvent new CustomEvent(name,
    bubbles: true
    detail: data
  )

