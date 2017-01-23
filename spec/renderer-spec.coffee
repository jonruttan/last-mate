path = require 'path'
fs = require 'fs-plus'

RendererRegistry = require '../lib/renderer-registry'
Renderer = require '../lib/renderer'

describe "Renderer tokenization", ->
  [renderer, registry] = []

  loadRendererSync = (name) ->
    registry.loadRendererSync(path.join(__dirname, 'fixtures', name))

  beforeEach ->
    registry = new RendererRegistry()
    loadRendererSync('text.json')
    loadRendererSync('html.json')

  describe "when the registry is empty", ->
    it "renders using the null renderer", ->
      emptyRegistry = new RendererRegistry()
      renderer = emptyRegistry.selectRenderer('js')
      # 'a = 1;'
      line = renderer.renderLines([[{"value":"a ","scopes":["source.js"]},{"value":"=","scopes":["source.js","keyword.operator.js"]},{"value":" ","scopes":["source.js"]},{"value":"1","scopes":["source.js","constant.numeric.js"]},{"value":";","scopes":["source.js","punctuation.terminator.statement.js"]}]])
      expect(line).toBe 'a = 1;'

    it "allows injections into the null renderer", ->
      registry = new RendererRegistry()
      loadRendererSync('text.json')

      line = registry.nullRenderer.renderLines([[{"value":"http://github.com","scopes":["text.plain.null-grammar","markup.underline.link.http.hyperlink"]}]])
      expect(line).toBe 'http://github.com'

  describe "Registry::loadRendererSync", ->
    it "returns a renderer for the file path specified", ->
      renderer = loadRendererSync('text.json')
      expect(fs.isFileSync(renderer.path)).toBe true
      expect(renderer).not.toBeNull()

      line = renderer.renderLines([[{"value":"hello world!","scopes":["text.plain.null-grammar"]}]])
      expect(line).toBe "hello world!\n"

  describe "::renderValue(token)", ->
    describe "using the null renderer", ->
      it "renders a value", ->
        renderer = new Renderer()
        token = renderer.renderValue("hello world!")
        expect(token).toBe 'hello world!'

    describe "using the text.plain renderer", ->
      it "renders a value", ->
        renderer = registry.selectRenderer('txt')
        token = renderer.renderValue("hello world!")
        expect(token).toBe 'hello world!'

    describe "using the text.html.basic renderer", ->
      it "renders a value", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderValue("hello world!")
        expect(token).toBe '<span>hello&nbsp;world!</span>'

  describe "::renderTokens(tokens)", ->
    describe "using the null renderer", ->
      it "renders an empty token array", ->
        renderer = new Renderer()
        token = renderer.renderTokens([])
        expect(token).toBe ''

      it "renders a token array of empty values", ->
        renderer = new Renderer()
        token = renderer.renderTokens([{"value":""},{"value":""},{"value":""}])
        expect(token).toBe ''

      it "renders a token array", ->
        renderer = new Renderer()
        token = renderer.renderTokens([{"value":"hello world!","scopes":["text.plain.null-grammar"]}])
        expect(token).toBe 'hello world!'

    describe "using the text.plain renderer", ->
      it "renders an empty token array", ->
        renderer = registry.selectRenderer('txt')
        token = renderer.renderTokens([])
        expect(token).toBe ''

      it "renders a token array of empty values", ->
        renderer = registry.selectRenderer('txt')
        token = renderer.renderTokens([{"value":""},{"value":""},{"value":""}])
        expect(token).toBe ''

      it "renders a token array", ->
        renderer = registry.selectRenderer('txt')
        token = renderer.renderTokens([{"value":"hello world!","scopes":["text.plain.null-grammar"]}])
        expect(token).toBe 'hello world!'

    describe "using the text.html.basic renderer", ->
      it "renders an empty token array", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderTokens([])
        expect(token).toBe ''

      it "renders a token array of empty values", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderTokens([{"value":""},{"value":""},{"value":""}])
        expect(token).toBe '<span></span><span></span><span></span>'

      it "renders a token array", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderTokens([{"value":"hello world!","scopes":["text.plain.null-grammar"]}])
        expect(token).toBe '<span class="text plain null-grammar"><span>hello&nbsp;world!</span></span>'

      it "minimizes the number of rendered scope tags", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderTokens([
          {"value":"hello world!","scopes":["text.plain.null-grammar"]}
          {"value":"hello world!","scopes":["text.plain.null-grammar"]}
        ])
        expect(token).toBe '<span class="text plain null-grammar"><span>hello&nbsp;world!</span><span>hello&nbsp;world!</span></span>'

  describe "::renderLine(lineTokens)", ->
    describe "using the null renderer", ->
      it "renders an empty token array", ->
        renderer = new Renderer()
        token = renderer.renderLine([])
        expect(token).toBe ''

      it "renders a token array of empty values", ->
        renderer = new Renderer()
        token = renderer.renderLine([{"value":""},{"value":""},{"value":""}])
        expect(token).toBe ''

      it "renders a token array", ->
        renderer = new Renderer()
        token = renderer.renderLine([{"value":"hello world!","scopes":["text.plain.null-grammar"]}])
        expect(token).toBe 'hello world!'

    describe "using the text.plain renderer", ->
      it "renders an empty token array", ->
        renderer = registry.selectRenderer('text')
        token = renderer.renderLine([])
        expect(token).toBe ''

      it "renders a token array of empty values", ->
        renderer = registry.selectRenderer('text')
        token = renderer.renderLine([{"value":""},{"value":""},{"value":""}])
        expect(token).toBe ''

      it "renders a token array", ->
        renderer = registry.selectRenderer('text')
        token = renderer.renderLine([{"value":"hello world!","scopes":["text.plain.null-grammar"]}])
        expect(token).toBe 'hello world!'

    describe "using the text.html.basic renderer", ->
      it "renders an empty token array", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderLine([])
        expect(token).toBe '<div class="line"></div>'

      it "renders a token array of empty values", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderLine([{"value":""},{"value":""},{"value":""}])
        expect(token).toBe '<div class="line"><span></span><span></span><span></span></div>'

      it "renders a token array", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderLine([{"value":"hello world!","scopes":["text.plain.null-grammar"]}])
        expect(token).toBe '<div class="line"><span class="text plain null-grammar"><span>hello&nbsp;world!</span></span></div>'


  describe "::renderLines(lineTokens, tagStack)", ->
    describe "using the null renderer", ->
      it "renders an empty array of line tokens", ->
        renderer = new Renderer()
        token = renderer.renderLines([])
        expect(token).toBe ''

      it "renders an array of empty line tokens", ->
        renderer = new Renderer()
        token = renderer.renderLines([ [], [], [] ])
        expect(token).toBe ''

      it "renders an array of line tokens with empty values", ->
        renderer = new Renderer()
        token = renderer.renderLines([
          [{"value":""},{"value":""},{"value":""}]
          [{"value":""},{"value":""},{"value":""}]
          [{"value":""},{"value":""},{"value":""}]
        ])
        expect(token).toBe ''

      it "renders an array of line tokens", ->
        renderer = new Renderer()
        token = renderer.renderLines([
          [{"value":"hello line 1!","scopes":["text.plain.null-grammar"]}]
          [{"value":"hello line 2!","scopes":["text.plain.null-grammar"]}]
        ])
        expect(token).toBe 'hello line 1!hello line 2!'

    describe "using the text.plain renderer", ->
      it "renders an empty array of line tokens", ->
        renderer = registry.selectRenderer('text')
        token = renderer.renderLines([])
        expect(token).toBe ''

      it "renders an array of empty line tokens", ->
        renderer = registry.selectRenderer('text')
        token = renderer.renderLines([ [], [], [] ])
        expect(token).toBe ''

      it "renders an array of line tokens with empty values", ->
        renderer = registry.selectRenderer('text')
        token = renderer.renderLines([
          [{"value":""},{"value":""},{"value":""}]
          [{"value":""},{"value":""},{"value":""}]
          [{"value":""},{"value":""},{"value":""}]
        ])
        expect(token).toBe ''

      it "renders an array of line tokens", ->
        renderer = registry.selectRenderer('text')
        token = renderer.renderLines([
          [{"value":"hello line 1!","scopes":["text.plain.null-grammar"]}]
          [{"value":"hello line 2!","scopes":["text.plain.null-grammar"]}]
        ])
        expect(token).toBe 'hello line 1!hello line 2!'

    describe "using the text.html.basic renderer", ->
      it "renders an empty array of line tokens", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderLines([])
        expect(token).toBe '<pre class="editor editor-colors"></pre>'

      it "renders an array of empty line tokens", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderLines([ [], [], [] ])
        expect(token).toBe '<pre class="editor editor-colors"><div class="line"></div><div class="line"></div><div class="line"></div></pre>'

        renderer = registry.selectRenderer('html')
        token = renderer.renderLines([
          [{"value":""},{"value":""},{"value":""}]
          [{"value":""},{"value":""},{"value":""}]
          [{"value":""},{"value":""},{"value":""}]
        ])
        expect(token).toBe '<pre class="editor editor-colors"><div class="line"><span></span><span></span><span></span></div><div class="line"><span></span><span></span><span></span></div><div class="line"><span></span><span></span><span></span></div></pre>'

      it "renders an array of line tokens", ->
        renderer = registry.selectRenderer('html')
        token = renderer.renderLines([
          [{"value":"hello line 1!","scopes":["text.plain.null-grammar"]}]
          [{"value":"hello line 2!","scopes":["text.plain.null-grammar"]}]
        ])
        expect(token).toBe '<pre class="editor editor-colors"><div class="line"><span class="text plain null-grammar"><span>hello&nbsp;line&nbsp;1!</span></span></div><div class="line"><span class="text plain null-grammar"><span>hello&nbsp;line&nbsp;2!</span></span></div></pre>'

  describe "when the renderer is activated/deactivated", ->
    it "adds/removes it from the registry", ->
      renderer = new Renderer(registry, {scopeName: 'test-activate'})

      renderer.deactivate()
      expect(registry.rendererForScopeName('test-activate')).toBeUndefined()

      renderer.activate()
      expect(registry.rendererForScopeName('test-activate')).toBe renderer

      renderer.deactivate()
      expect(registry.rendererForScopeName('test-activate')).toBeUndefined()
