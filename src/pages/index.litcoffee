Main page script. Not particularly interesting as everything is an element.

    require '../elements/elementmixin.litcoffee'
    page = require 'page'

    document.addEventListener 'configured', (evt) ->
      document.querySelector('#loading').hideAnimated()
      page '/', (ctx) ->
        clientid = ctx.hash.match(/callme\/(.*)/)?[1]
        document.querySelector('conference-room').call clientid
      page()
      page "#callme/#{evt.detail.clientid}"

