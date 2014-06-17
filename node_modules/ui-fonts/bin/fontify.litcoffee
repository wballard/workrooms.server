#!/usr/bin/env coffee

This collects the available font files and prepares them as data
for rendering. No real arguments, just read one file that is a template
and write to standard out.

    fs = require 'fs'
    path = require 'path'
    handlebars = require 'handlebars'

    fonts = {}

    fs.readdirSync(process.argv[2]).forEach (font) ->
      fontName = path.basename(font, '.woff')
      fontPath = path.join process.argv[2], font
      fonts[fontName] = fs.readFileSync(fontPath).toString('base64')

    template = handlebars.compile(fs.readFileSync(process.argv[3]).toString('utf8'))

    console.log template(fonts)
