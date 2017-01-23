path = require 'path'

_ = require 'underscore-plus'
fs = require 'fs-plus'
{Emitter} = require 'event-kit'
Grim = require 'grim'

regexen = require './regexen'
TagStack = require './tag-stack'

pathSplitRegex = new RegExp("[/.]")

# Extended: Renderer that converts tokenized lines of text to a markup format.
#
# This class should not be instantiated directly but instead obtained from
# a {RendererRegistry} by calling {RendererRegistry::loadRenderer}.
module.exports =
class Renderer
  registration: null

  constructor: (@registry, options={}) ->
    {@fileTypes, @name, @scopeName, @tab, @tags, @translations} = options
    @emitter = new Emitter
    @fileTypes ?= []
    @includedRendererScopes = []

  # Public: Create a TagStack for this Renderer.
  #
  # * `array` An optional scope {Array} to pass to the constructor.
  # * `tag` An optional tag {Object} to pass to the constructor.
  #
  # Returns a {TagStack} object.
  createTagStack: (array, tag) ->
    new TagStack {@tab, @translations}, array, tag

  ###
  Section: Event Subscription
  ###

  # Public: Invoke the given callback when this renderer is updated due to a
  # renderer it depends on being added or removed from the registry.
  #
  # * `callback` {Function} to call when this renderer is updated.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  ###
  Section: Rendering
  ###

  # Public: Render all lines in the given line token array.
  #
  # * `lineTokens` An {Array} of token arrays for each line.
  # * `tagStack` A {TagStack} object for holding the state of the renderer.
  #
  # Returns a {String} representation of the line token array rendered with the
  # *`body`* tag rules defined in this object's markup format.
  renderLines: (lineTokens, tagStack=@createTagStack()) ->
    outputArray = []
    outputArray.push tagStack.push 'body', @tags?.body
    for tokens in lineTokens
      outputArray.push @renderLine tokens, tagStack
    outputArray.push tagStack.pop()
    outputArray.join ''

  # Public: Render a line token array.
  #
  # * `tokens` An {Array} of tokens to render.
  # * `tagStack` A {TagStack} object for holding the state of the renderer.
  #
  # Returns a {String} representation of the token array rendered with the
  # *`line`* tag rules defined in this object's markup format.
  renderLine: (tokens, tagStack=@createTagStack()) ->
    outputArray = []
    outputArray.push tagStack.push 'line', @tags?.line
    outputArray.push @renderTokens tokens, @createTagStack()
    outputArray.push tagStack.pop()
    outputArray.join ''

  # Public: Render a token array.
  #
  # * `tokens` An {Array} of tokens to render.
  # * `tagStack` A {TagStack} object for holding the state of the renderer. This
  #              will be drained, rendering all closing tags on the stack,
  #              before the function exits.
  #
  # Returns a {String} representation of the token array rendered with the
  # *`scope`* tag rules defined in this object's markup format.
  renderTokens: (tokens, tagStack=@createTagStack()) ->
    outputArray = []
    for token in tokens
      outputArray.push tagStack.sync @createTagStack(token.scopes, @tags?.scope or true)
      outputArray.push @renderValue token.value, tagStack

    while tagStack.length() > 0
      outputArray.push tagStack.pop()

    outputArray.join ''

  # Public: Render a token value.
  #
  # * `value` A {String} value.
  # * `tagStack` A {TagStack} object for holding the state of the renderer.
  #
  # Returns a {String} representation of the token value rendered with the
  # *`value`* tag rules defined in this object's markup format.
  renderValue: (value, tagStack=@createTagStack()) ->
    outputArray = []
    # value = ' ' unless value
    value = regexen.replaceAll value, tags if tags = @tags?.value?.escape
    outputArray.push tagStack.push 'value', @tags?.value
    outputArray.push tagStack.replaceBackReferences value
    outputArray.push tagStack.pop()
    outputArray.join ''

  activate: ->
    @registration = @registry.addRenderer(this)

  deactivate: ->
    @emitter = new Emitter
    @registration?.dispose()
    @registration = null

  rendererUpdated: (scopeName) ->
    return false unless _.include @includedGrammarScopes, scopeName
    @registry.rendererUpdated @scopeName
    @emit 'renderer-updated' if Grim.includeDeprecatedAPIs
    @emitter.emit 'did-update'
    true

  getScore: (filePath) ->
    if @registry.rendererOverrideForPath(filePath) is @scopeName
      2 + (filePath?.length ? 0)
    else
      @getPathScore filePath

  getPathScore: (filePath) ->
    return -1 unless filePath

    filePath = filePath.replace(/\\/g, '/') if process.platform is 'win32'

    pathComponents = filePath.toLowerCase().split pathSplitRegex
    pathScore = -1
    for fileType in @fileTypes
      fileTypeComponents = fileType.toLowerCase().split pathSplitRegex
      pathSuffix = pathComponents[-fileTypeComponents.length..-1]
      if _.isEqual pathSuffix, fileTypeComponents
        pathScore = Math.max pathScore, fileType.length

    pathScore

if Grim.includeDeprecatedAPIs
  EmitterMixin = require('emissary').Emitter
  EmitterMixin.includeInto Renderer

  Renderer::on = (eventName) ->
    if eventName is 'did-update'
      Grim.deprecate 'Call Renderer::onDidUpdate instead'
    else
      Grim.deprecate 'Call explicit event subscription methods instead'

    EmitterMixin::on.apply(this, arguments)
