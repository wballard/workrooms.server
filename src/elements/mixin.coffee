###
This is a mixin method that adds utilities directly to a custom element, just
call it inside of `createdCallback(this)` and the methods will be attached.
###

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
