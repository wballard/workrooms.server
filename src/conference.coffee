###
Build and control the entire conference page
###

getUserMedia = require('getusermedia')

console.log 'conference tab'

getUserMedia (err, stream) ->
  console.log arguments
  if err
    console.log err
  else
    console.log stream
