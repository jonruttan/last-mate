path = require 'path'

_ = require 'underscore-plus'
fs = require 'fs-plus'
{Emitter} = require 'event-kit'
Grim = require 'grim'

TagStack = require './tag-stack'

pathSplitRegex = new RegExp("[/.]")

# Local: Apply an array of RegExp search/replace expressions on a string.
#
# * `string` {String} to transform.
# * `regexen` {Array} of {Objects} containing a `pattern` to apply and a
#   `replace` expression.
#
# Returns a {String} with the tranformations applied.
replace = (string, regexen) ->
  for regex in regexen
    string = string.replace new RegExp(regex.pattern, 'g'), regex.replace
  string

# Extended: Renderer that converts tokenized lines of text to a markup format.
#
# This class should not be instantiated directly but instead obtained from
# a {RendererRegistry} by calling {RendererRegistry::loadRenderer}.
module.exports =
class Renderer
  registration: null

  constructor: (@registry, options={}) ->
    {@name, @fileTypes, @scopeName, @tags} = options

    @emitter = new Emitter

    @fileTypes ?= []
    @includedRendererScopes = []

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
  renderLines: (lineTokens, tagStack=new TagStack()) ->
    outputArray = []
    outputArray.push tagStack.push 'body', @tags?.body
    for tokens in lineTokens
      outputArray.push @renderLine(tokens, tagStack)
    outputArray.push tagStack.pop()
    outputArray.join ''

  # Public: Render a line token array.
  #
  # * `tokens` An {Array} of tokens to render.
  # * `tagStack` A {TagStack} object for holding the state of the renderer.
  #
  # Returns a {String} representation of the token array rendered with the
  # *`line`* tag rules defined in this object's markup format.
  renderLine: (tokens, tagStack=new TagStack()) ->
    outputArray = []
    outputArray.push tagStack.push 'line', @tags?.line
    outputArray.push @renderTokens(tokens, new TagStack())
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
  renderTokens: (tokens, tagStack=new TagStack()) ->
    outputArray = []
    for token in tokens
      outputArray.push tagStack.sync(new TagStack(token.scopes, @tags?.scope or true))
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
  renderValue: (value, tagStack=new TagStack()) ->
    outputArray = []
    # value = ' ' unless value
    value = replace value, tags if tags = @tags?.entities?.escape
    outputArray.push tagStack.push 'value', @tags?.value
    outputArray.push value
    outputArray.push tagStack.pop()
    outputArray.join ''

  activate: ->
    @registration = @registry.addRenderer(this)

  deactivate: ->
    @emitter = new Emitter
    @registration?.dispose()
    @registration = null

  rendererUpdated: (scopeName) ->
    return false unless _.include(@includedGrammarScopes, scopeName)
    @registry.rendererUpdated(@scopeName)
    @emit 'renderer-updated' if Grim.includeDeprecatedAPIs
    @emitter.emit 'did-update'
    true

  getScore: (filePath) ->
    if @registry.rendererOverrideForPath(filePath) is @scopeName
      2 + (filePath?.length ? 0)
    else
      @getPathScore(filePath)

  getPathScore: (filePath) ->
    return -1 unless filePath

    filePath = filePath.replace(/\\/g, '/') if process.platform is 'win32'

    pathComponents = filePath.toLowerCase().split(pathSplitRegex)
    pathScore = -1
    for fileType in @fileTypes
      fileTypeComponents = fileType.toLowerCase().split(pathSplitRegex)
      pathSuffix = pathComponents[-fileTypeComponents.length..-1]
      if _.isEqual(pathSuffix, fileTypeComponents)
        pathScore = Math.max(pathScore, fileType.length)

    pathScore

if Grim.includeDeprecatedAPIs
  EmitterMixin = require('emissary').Emitter
  EmitterMixin.includeInto(Renderer)

  Renderer::on = (eventName) ->
    if eventName is 'did-update'
      Grim.deprecate("Call Renderer::onDidUpdate instead")
    else
      Grim.deprecate("Call explicit event subscription methods instead")

    EmitterMixin::on.apply(this, arguments)
