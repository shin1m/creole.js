# creole.js [![Build Status](https://secure.travis-ci.org/shin1m/creole.js.png)](http://travis-ci.org/shin1m/creole.js)

creole.js is a [Creole 1.0](http://wikicreole.org/wiki/Creole1.0) parser for javascript.

It can run on both client side and server side.


## How to Use

    class Builder
      start: (name, options) ->
      end: ->
      text: (value) ->

    require('creole').parse new Builder, 'creole...'


## Example Builder

In html.coffee:

    class Builder
      constructor: (@e, @u) -> @context = []
      bold:
        start: -> @u '<strong>'
        end: -> @u '</strong>'
      ...
      link:
        start: (options) ->
          @u '<a href="'
          @e options.link
          @u '">'
        end: -> @u '</a>'
      ...
      start: (name, options) ->
        handler = @[name]
        if handler?
          @context.push handler
          handler.start.call @, options
        else
          @context.push null
      end: ->
        @context.pop()?.end.call @
      text: (value) -> @e value

    exports = module?.exports ? {}
    window.html = exports if window?
    exports.Builder = Builder


## Client Side Example

In demo.html:

    <!DOCTYPE html>
    <html>
    <head>
    <title>creole.js Live Demo</title>
    </head>
    <body>
    <div id="preview"></div>
    <textarea id="source" rows="8" cols="80">
    = creole.js Live Demo

    creole.js is a [[http://wikicreole.org/wiki/Creole1.0|Creole 1.0]] parser for javascript.

    It can run on both client side and server side.

    ----
    Edit the source below.
    </textarea>
    <script src="http://code.jquery.com/jquery-latest.js"></script>
    <script src="creole.js"></script>
    <script src="html.js"></script>
    <script>
        var escapes = {'&': '&amp;', '"': '&quot;', '<': '&lt;', '>': '&gt;'};
        var preview = function() {
            var result = [];
            var builder = new html.Builder(function(value) {
                result.push(value.replace(/[&"<>]/g, function(c) {
                    return escapes[c];
                }));
            }, function(value) {
                result.push(value);
            });
            creole.parse(builder, $('#source').val());
            $('#preview').html(result.join(''));
        };
        $('#source').data('preview', null).on('input', function() {
            clearTimeout($(this).data('preview'));
            $(this).data('preview', setTimeout(preview, 500));
        });
        preview();
    </script>
    </body>
    </html>


## Server Side Example

In app.coffee:

    ...
    creole = require 'creole'
    html = require 'html'

    app.get '/', (req, res) ->
      res.render 'index',
        creole: (escaped, unescaped, content) ->
          creole.parse new html.Builder(escaped, unescaped), content
        content: '''
          = creole.js Live Demo

          creole.js is a [[http://wikicreole.org/wiki/Creole1.0|Creole 1.0]] parser for javascript.

          It can run on both client side and server side.
        '''
    ...

In index.jade:

    .preview
      - creole(function(value) {
        = value
      - }, function(value) {
        != value
      - }, content)


## License

The MIT License (MIT)

Copyright (c) 2012 Shin-ichi MORITA

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
