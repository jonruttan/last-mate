_ = require 'underscore-plus'
CSON = require 'season'
{Emitter, Disposable} = require 'event-kit'
Grim = require 'grim'

Renderer = require './renderer'
NullRenderer = require './null-renderer'

# Extended: Registry containing one or more renderers.
module.exports =
class RendererRegistry
  constructor: (options={}) ->
    @emitter = new Emitter
    @renderers = []
    @renderersByScopeName = {}
    @injectionRenderers = []
    @rendererOverridesByPath = {}
    @nullRenderer = new NullRenderer(this)
    @addRenderer(@nullRenderer)

  ###
  Section: Event Subscription
  ###

  # Public: Invoke the given callback when a renderer is added to the registry.
  #
  # * `callback` {Function} to call when a renderer is added.
  #   * `renderer` {Renderer} that was added.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidAddRenderer: (callback) ->
    @emitter.on 'did-add-renderer', callback

  # Public: Invoke the given callback when a renderer is updated due to a renderer
  # it depends on being added or removed from the registry.
  #
  # * `callback` {Function} to call when a renderer is updated.
  #   * `renderer` {Renderer} that was updated.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidUpdateRenderer: (callback) ->
    @emitter.on 'did-update-renderer', callback

  ###
  Section: Managing Renderers
  ###

  # Public: Get all the renderers in this registry.
  #
  # Returns a non-empty {Array} of {Renderer} instances.
  getRenderers: ->
    _.clone(@renderers)

  # Public: Get a renderer with the given scope name.
  #
  # * `scopeName` A {String} such as `"source.js"`.
  #
  # Returns a {Renderer} or undefined.
  rendererForScopeName: (scopeName) ->
    @renderersByScopeName[scopeName]

  # Public: Add a renderer to this registry.
  #
  # A 'renderer-added' event is emitted after the renderer is added.
  #
  # * `renderer` The {Renderer} to add. This should be a value previously returned
  #   from {::readRenderer} or {::readRendererSync}.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to remove the
  # renderer.
  addRenderer: (renderer) ->
    @renderers.push(renderer)
    @renderersByScopeName[renderer.scopeName] = renderer
    @injectionRenderers.push(renderer) if renderer.injectionSelector?
    @rendererUpdated(renderer.scopeName)
    @emit 'renderer-added', renderer if Renderer.includeDeprecatedAPIs
    @emitter.emit 'did-add-renderer', renderer
    new Disposable => @removeRenderer(renderer)

  removeRenderer: (renderer) ->
    _.remove(@renderers, renderer)
    delete @renderersByScopeName[renderer.scopeName]
    _.remove(@injectionRenderers, renderer)
    @rendererUpdated(renderer.scopeName)
    undefined

  # Public: Remove the renderer with the given scope name.
  #
  # * `scopeName` A {String} such as `"source.js"`.
  #
  # Returns the removed {Renderer} or undefined.
  removeRendererForScopeName: (scopeName) ->
    renderer = @rendererForScopeName(scopeName)
    @removeRenderer(renderer) if renderer?
    renderer

  # Public: Read a renderer synchronously but don't add it to the registry.
  #
  # * `rendererPath` A {String} absolute file path to a renderer file.
  #
  # Returns a {Renderer}.
  readRendererSync: (rendererPath) ->
    renderer = CSON.readFileSync(rendererPath) ? {}
    if typeof renderer.scopeName is 'string' and renderer.scopeName.length > 0
      @createRenderer(rendererPath, renderer)
    else
      throw new Error("Renderer missing required scopeName property: #{rendererPath}")

  # Public: Read a renderer asynchronously but don't add it to the registry.
  #
  # * `rendererPath` A {String} absolute file path to a renderer file.
  # * `callback` A {Function} to call when read with the following arguments:
  #   * `error` An {Error}, may be null.
  #   * `renderer` A {Renderer} or null if an error occured.
  #
  # Returns undefined.
  readRenderer: (rendererPath, callback) ->
    CSON.readFile rendererPath, (error, renderer={}) =>
      if error?
        callback?(error)
      else
        if typeof renderer.scopeName is 'string' and renderer.scopeName.length > 0
          callback?(null, @createRenderer(rendererPath, renderer))
        else
          callback?(new Error("Renderer missing required scopeName property: #{rendererPath}"))

    undefined

  # Public: Read a renderer synchronously and add it to this registry.
  #
  # * `rendererPath` A {String} absolute file path to a renderer file.
  #
  # Returns a {Renderer}.
  loadRendererSync: (rendererPath) ->
    renderer = @readRendererSync(rendererPath)
    @addRenderer(renderer)
    renderer

  # Public: Read a renderer asynchronously and add it to the registry.
  #
  # * `rendererPath` A {String} absolute file path to a renderer file.
  # * `callback` A {Function} to call when loaded with the following arguments:
  #   * `error` An {Error}, may be null.
  #   * `renderer` A {Renderer} or null if an error occured.
  #
  # Returns undefined.
  loadRenderer: (rendererPath, callback) ->
    @readRenderer rendererPath, (error, renderer) =>
      if error?
        callback?(error)
      else
        @addRenderer(renderer)
        callback?(null, renderer)

    undefined

  # Public: Get the renderer override for the given file path.
  #
  # * `filePath` A {String} file path.
  #
  # Returns a {Renderer} or undefined.
  rendererOverrideForPath: (filePath) ->
    @rendererOverridesByPath[filePath]

  # Public: Set the renderer override for the given file path.
  #
  # * `filePath` A non-empty {String} file path.
  # * `scopeName` A {String} such as `"source.js"`.
  #
  # Returns a {Renderer} or undefined.
  setRendererOverrideForPath: (filePath, scopeName) ->
    if filePath
      @rendererOverridesByPath[filePath] = scopeName

  # Public: Remove the renderer override for the given file path.
  #
  # * `filePath` A {String} file path.
  #
  # Returns undefined.
  clearRendererOverrideForPath: (filePath) ->
    delete @rendererOverridesByPath[filePath]
    undefined

  # Public: Remove all renderer overrides.
  #
  # Returns undefined.
  clearRendererOverrides: ->
    @rendererOverridesByPath = {}
    undefined

  # Public: Select a renderer for the given file path and file contents.
  #
  # This picks the best match by checking the file path and contents against
  # each renderer.
  #
  # * `filePath` A {String} file path.
  # * `fileContents` A {String} of text for the file path.
  #
  # Returns a {Renderer}, never null.
  selectRenderer: (filePath, fileContents) ->
    _.max @renderers, (renderer) -> renderer.getScore(filePath, fileContents)

  createToken: (value, scopes) -> {value, scopes}

  rendererUpdated: (scopeName) ->
    for renderer in @renderers when renderer.scopeName isnt scopeName
      if renderer.rendererUpdated(scopeName)
        @emit 'renderer-updated', renderer if Renderer.includeDeprecatedAPIs
        @emitter.emit 'did-update-renderer', renderer
    return

  createRenderer: (rendererPath, object) ->
    renderer = new Renderer(this, object)
    renderer.path = rendererPath
    renderer

if Grim.includeDeprecatedAPIs
  EmitterMixin = require('emissary').Emitter
  EmitterMixin.includeInto(RendererRegistry)

  RendererRegistry::on = (eventName) ->
    switch eventName
      when 'renderer-added'
        Grim.deprecate("Call RendererRegistry::onDidAddRenderer instead")
      when 'renderer-updated'
        Grim.deprecate("Call RendererRegistry::onDidUpdateRenderer instead")
      else
        Grim.deprecate("Call explicit event subscription methods instead")

    EmitterMixin::on.apply(this, arguments)
