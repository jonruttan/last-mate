path = require 'path'

_ = require 'underscore-plus'

regexen = require './regexen'

pathSplitRegex = new RegExp '[/.]'

# Extended: Renderer that converts tokenized lines of text to a markup format.
#
# This class should not be instantiated directly but instead obtained from
# a {RendererRegistry} by calling {RendererRegistry::loadRenderer}.
module.exports =
class TagStack
  constructor: (options = {}, @array=[], tag) ->
    {@counts, @tab, @translations} = options
    @counts ?= {}
    @tab ?= '\t'
    @translations ?= {}

    @array = ({scope, tag} for scope in @array) if tag

    for frame in @array
      @counts[frame.scope] ?= 0
      @counts[frame.scope] += 1


  # Public: Return the length of the scope array.
  #
  # Returns a {Number} representing the length of the scope array.
  length: ->
    @array.length

  # Public: Replaces all instances of an escaped back-reference *(i.e. \0) with
  # the referenced tag's scope.
  #
  # **NOTE:** We're trying to keep the syntax the same as the *first-mate*
  #           RegExp, so we use `\\0` rather than using `$&` for the insertion
  #           of the matched substring, and `\\n` for the *nth* parenthesized
  #           submatch string.
  #
  # * `string` A {String} containing back-references.
  #
  # Returns a {String} with the back-referenced scopes.
  replaceBackReferences: (string) ->
    string = string
      .replace /\\t/g, @tab
      .replace /\\T/g, @tab.repeat @array.length
      .replace /\\L/g, @array.length
      .replace /\\N/g, @array.length and @counts[@array[@array.length - 1].scope] or 0

    return string if not @array.length

    string.replace /\\(\d+)/g, (match, offset) =>
      return '' if offset >= @array.length

      frame = Object.create @array[@array.length - 1 - offset]
      frame.scope = regexen.replaceAll(frame.scope, frame.tag.escape) if frame.tag.escape?

      if frame.scope of @translations
        frame.scope = @translations[frame.scope]
      else if '.' of @translations
        frame.scope = regexen.replaceAll frame.scope, @translations['.']

      frame.scope

  # Public: Push a scope {String} onto a scope array.
  #
  # * `scope` A {String} containing the scope name.
  # * `tag` An object with `open` and `close` tag replace patterns.
  #
  # Returns a {String} with an opening scope tag.
  push: (scope, tag={}) ->
    @counts[scope] ?= 0
    @counts[scope] += 1
    @array.push scope: scope, tag: tag

    return '' if not tag.open?

    @replaceBackReferences tag.open

  # Public: Pop a scope off of a scope array.
  #
  # Returns a {String} with an closing scope tag.
  pop: ->
    frame = @array[@array.length - 1]
    scope = ''

    scope = @replaceBackReferences frame.tag.close if frame.tag?.close?

    return '' if not frame = @array.pop()

    scope

  # Public: Return the tags required to synchronize the internal scope state to
  # with a desired scope.
  #
  # * `desired` The desired state array as an {Array} of scope names.
  #
  # Returns a {String} representation of the tags required to synchronze the
  # states.
  sync: (desired) ->
    outputArray = []
    excess = @array.length - desired.array.length
    if excess > 0
      outputArray.push(@pop(@array)) while excess--

    # pop until common prefix
    for i in [@array.length..0]
      break if _.isEqual(@array[0...i], desired.array[0...i])
      outputArray.push @pop()

    # push on top of common prefix until @array is desired
    for j in [i...desired.array.length]
      outputArray.push @push(desired.array[j].scope, desired.array[j].tag)

    outputArray.join ''
