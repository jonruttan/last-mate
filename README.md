# First Mate [![Build Status](https://travis-ci.org/jonruttan/last-mate.svg?branch=master)](https://travis-ci.org/jonruttan/last-mate)

A rendering engine for tokens generated with TextMate-style grammars; [atom/first-mate](https://github.com/atom/first-mate)'s missing counterpart.

## Installing

```sh
npm install last-mate
```

## Using

### RendererRegistry

```coffeescript
{RendererRegistry} = require 'last-mate'
registry = new RendererRegistry()
renderer = registry.loadRendererSync('./spec/fixtures/javascript.json')
{tokens} = renderer.tokenizeLine('var offset = 3;')
for {value, scopes} in tokens
  console.log("Token text: '#{value}' with scopes: #{scopes}")
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

#### renderLine(line, [ruleStack], [firstLine])

Generate the tokenize for the given line of text.

`line` - The string text of the line.

`ruleStack` - An array of Rule objects that was returned from a previous call
to this method.

`firstLine` - `true` to indicate that the very first line is being tokenized.

Returns an object with a `tokens` key pointing to an array of token objects
and a `ruleStack` key pointing to an array of rules to pass to this method
on future calls for lines proceeding the line that was just tokenized.

#### tokenizeLines(text)

`text` - The string text possibly containing newlines.

Returns an array of tokens for each line tokenized.

## Developing

  * Clone the repository
  * Run `npm install`
  * Run `npm test` to run the specs
  * Run `npm run benchmark` to benchmark fully tokenizing jQuery 2.0.3 and
    the CSS for Twitter Bootstrap 3.1.1
