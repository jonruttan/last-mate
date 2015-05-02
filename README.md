# Last Mate [![Build Status](https://travis-ci.org/jonruttan/last-mate.svg?branch=master)](https://travis-ci.org/jonruttan/last-mate)

A rendering engine for tokens generated with TextMate-style grammars. Last Mate
is the rendering counterpart to [atom/first-mate](https://github.com/atom/first-mate)'s
lexer.

## Installing

```sh
npm install last-mate
```

## Using

### RendererRegistry

```coffeescript
{RendererRegistry} = require 'last-mate'
registry = new RendererRegistry()
renderer = registry.loadRendererSync('./spec/fixtures/html.json')
html = renderer.renderLines([
  [
    {
      "value": "var",
      "scopes": [
        "source.js",
        "storage.modifier.js"
      ]
    },
    {
      "value": " offset ",
      "scopes": [
        "source.js"
      ]
    },
    {
      "value": "=",
      "scopes": [
        "source.js",
        "keyword.operator.js"
      ]
    },
    {
      "value": " ",
      "scopes": [
        "source.js"
      ]
    },
    {
      "value": "3",
      "scopes": [
        "source.js",
        "constant.numeric.js"
      ]
    },
    {
      "value": ";",
      "scopes": [
        "source.js",
        "punctuation.terminator.statement.js"
      ]
    }
  ]
])
console.log(html)
```

Outputs
```html
<pre class="editor editor-colors"><div class="line"><span class="source js"><span class="storage modifier js"><span>var</span></span><span>&nbsp;offset&nbsp;</span><span class="keyword operator js"><span>=</span></span><span>&nbsp;</span><span class="constant numeric js"><span>3</span></span><span class="punctuation terminator statement js"><span>;</span></span></span></div></pre>
```

#### loadRenderer(rendererPath, callback)

Asynchronously load a renderer and add it to the registry.

`rendererPath` - A string path to the renderer file.

`callback` - A function to call after the renderer is read and added to the
registry.  The callback receives `(error, renderer)` arguments.

#### loadRendererSync(rendererPath)

Synchronously load a renderer and add it to the registry.

`rendererPath` - A string path to the renderer file.

Returns a `Renderer` instance.

### Renderer

#### renderLines(lineTokens, tagStack=new TagStack())

Render all lines in the given line token array.

`lineTokens` - An array of token arrays for each line.
`tagStack` - A TagStack object for holding the state of the renderer.

`tagStack` - An array of Rule objects that was returned from a previous call
to this method.

Returns a string representation of the line token array rendered with the
*`body`* tag rules defined in this object's markup format.

#### renderLine(tokens, tagStack=new TagStack())

`tokens` - An array of tokens to render.
`tagStack` - A TagStack object for holding the state of the renderer.

Returns a string representation of the token array rendered with the *`line`*
tag rules defined in this object's markup format.

#### renderTokens(tokens, tagStack=new TagStack())

`tokens` - An array of tokens to render.
`tagStack` - A TagStack object for holding the state of the renderer. This
             stack will be drained, rendering all closing tags on it, before the
             function exits.

Returns a string representation of the token array rendered with the
*`scope`* tag rules defined in this object's markup format.

#### renderValue(value, tagStack=new TagStack())

`tokens` - An array of tokens to render.
`tagStack` - A TagStack object for holding the state of the renderer.

Returns a string representation of the token value rendered with the
*`value`* tag rules defined in this object's markup format.

## Developing

  * Clone the repository
  * Run `npm install`
  * Run `npm test` to run the specs
  * Run `npm run benchmark` to benchmark fully rendering jQuery 2.0.3 and
    the CSS for Twitter Bootstrap 3.1.1
