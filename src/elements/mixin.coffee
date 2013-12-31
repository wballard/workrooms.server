###
This is a mixin method that adds utilities directly to a custom element, just
call it inside of `createdCallback(this)` and the methods will be attached.
###


#Patch NodeList to be useful like an Array
arrayMethods = Object.getOwnPropertyNames(Array.prototype)
arrayMethods.forEach (methodName) ->
  NodeList.prototype[methodName] = Array.prototype[methodName]

module.exports = (object) ->
  ###
  Macro to define a property that will fire off the `attributeChangedCallback`
  as defined in WebComponents.
  ###
  object.defineCustomElementProperty = (name) ->
    Object.defineProperty object, name,
      get: -> object.getAttribute(name)
      set: (value) -> object.setAttribute(name, value)
      configurable: true
      enumerable: true
  ###
  Fire off a custom event with the supplied detail. This is a full on bubbling
  DOM event.
  ###
  object.fire = (name, data) ->
    object.dispatchEvent new CustomEvent(name,
      bubbles: true
      detail: data
    )
