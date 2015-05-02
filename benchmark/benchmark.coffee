path = require 'path'
fs = require 'fs-plus'
CSON = require 'season'
TextLex = require 'textlex'
RendererRegistry = require '../lib/renderer-registry'

registry = new RendererRegistry()
textRenderer = registry.loadRendererSync(path.resolve(__dirname, '..', 'spec', 'fixtures', 'text.json'))
htmlRenderer = registry.loadRendererSync(path.resolve(__dirname, '..', 'spec', 'fixtures', 'html.json'))

render = (renderer, tokens) ->
  start = Date.now()
  content = renderer.renderLines(tokens)
  duration = Date.now() - start
  tokenCount = tokens.reduce ((count, line) -> count + line.length), 0
  tokensPerMillisecond = Math.round(tokenCount / duration)
  console.log "Rendered #{tokenCount} tokens in #{duration}ms (#{tokensPerMillisecond} tokens/ms)"
  content

renderFile = (renderer, file, title) ->
  console.log()
  tokenPath = path.join(__dirname, 'cache', "#{file}.tokens.json")
  filePath = path.join(__dirname, file)
  if not fs.existsSync tokenPath
    console.log("Lexing and caching #{title} (once)")
    textlexer = new TextLex()
    tokens = textlexer.lexSync({filePath, scopeName: 'source.js'})
    fs.writeFileSync(tokenPath, JSON.stringify(tokens, null, 0))
  else
    tokens = CSON.readFileSync(tokenPath)

  console.log("Rendering #{title}")
  content = render(renderer, tokens)

for name, renderer of { text: textRenderer, html: htmlRenderer}
  console.log()
  console.log "Using #{name} renderer"
  renderFile(renderer, 'large.js', 'jQuery v2.0.3')
  renderFile(renderer, 'large.min.js', 'jQuery v2.0.3 minified')
  renderFile(renderer, 'bootstrap.css', 'Bootstrap CSS v3.1.1')
  renderFile(renderer, 'bootstrap.min.css', 'Bootstrap CSS v3.1.1 minified')
