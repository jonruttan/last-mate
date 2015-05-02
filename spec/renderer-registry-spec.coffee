path = require 'path'
RendererRegistry = require '../lib/renderer-registry'

describe "RendererRegistry", ->
  registry = null

  loadRendererSync = (name) ->
    registry.loadRendererSync(path.join(__dirname, 'fixtures', name))

  describe "renderer overrides", ->
    it "stores the override scope name for a path", ->
      registry = new RendererRegistry()

      expect(registry.rendererOverrideForPath('foo.txt')).toBeUndefined()
      expect(registry.rendererOverrideForPath('bar.txt')).toBeUndefined()

      registry.setRendererOverrideForPath('foo.txt', 'dest.html')
      expect(registry.rendererOverrideForPath('foo.txt')).toBe 'dest.html'

      registry.setRendererOverrideForPath('bar.txt', 'dest.markdown')
      expect(registry.rendererOverrideForPath('bar.txt')).toBe 'dest.markdown'

      registry.clearRendererOverrideForPath('foo.txt')
      expect(registry.rendererOverrideForPath('foo.txt')).toBeUndefined()
      expect(registry.rendererOverrideForPath('bar.txt')).toBe 'dest.markdown'

      registry.clearRendererOverrides()
      expect(registry.rendererOverrideForPath('bar.txt')).toBeUndefined()

      registry.setRendererOverrideForPath('', 'dest.markdown')
      expect(registry.rendererOverrideForPath('')).toBeUndefined()

      registry.setRendererOverrideForPath(null, 'dest.markdown')
      expect(registry.rendererOverrideForPath(null)).toBeUndefined()

      registry.setRendererOverrideForPath(undefined, 'dest.markdown')
      expect(registry.rendererOverrideForPath(undefined)).toBeUndefined()

  describe "::selectRenderer", ->
    it "always returns a renderer", ->
      registry = new RendererRegistry()
      expect(registry.selectRenderer().scopeName).toBe 'text.plain.null-renderer'

    it "selects the text.plain renderer over the null renderer", ->
      registry = new RendererRegistry()
      loadRendererSync('text.json')

      expect(registry.selectRenderer('test.txt').scopeName).toBe 'text.plain'

    it "selects a renderer based on the file path case insensitively", ->
      registry = new RendererRegistry()
      loadRendererSync('text.json')
      loadRendererSync('html.json')

      expect(registry.selectRenderer('/tmp/dest.html').scopeName).toBe 'text.html.basic'
      expect(registry.selectRenderer('/tmp/dest.HTML').scopeName).toBe 'text.html.basic'

    describe "on Windows", ->
      originalPlatform = null

      beforeEach ->
        originalPlatform = process.platform
        Object.defineProperty process, 'platform', value: 'win32'

      afterEach ->
        Object.defineProperty process, 'platform', value: originalPlatform

      it "normalizes back slashes to forward slashes when matching the fileTypes", ->
        registry = new RendererRegistry()
        loadRendererSync('file-types-with-slashes.json')

        expect(registry.selectRenderer('C:\\.atom\\hello').scopeName).toBe 'fileTypes.withSlashes'
        expect(registry.selectRenderer('/a/b/c/.atom/hello').scopeName).toBe 'fileTypes.withSlashes'

  describe "when the scope doesn't exist", ->
    it "throws an error", ->
      rendererPath = path.join(__dirname, 'fixtures', '')
      registry = new RendererRegistry()
      expect(-> registry.loadRendererSync(rendererPath)).toThrow()

      callback = jasmine.createSpy('callback')
      registry.loadRenderer(rendererPath, callback)

      waitsFor ->
        callback.callCount is 1

      runs ->
        expect(callback.argsForCall[0][0].message.length).toBeGreaterThan 0

  describe "when the renderer has no scope name", ->
    it "throws an error", ->
      rendererPath = path.join(__dirname, 'fixtures', 'no-scope-name.json')
      registry = new RendererRegistry()
      expect(-> registry.loadRendererSync(rendererPath)).toThrow()

      callback = jasmine.createSpy('callback')
      registry.loadRenderer(rendererPath, callback)

      waitsFor ->
        callback.callCount is 1

      runs ->
        expect(callback.argsForCall[0][0].message.length).toBeGreaterThan 0
