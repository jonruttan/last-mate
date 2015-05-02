path = require 'path'

_ = require 'underscore-plus'

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
class TagStack
  constructor: (@array=[], tag) ->
    @array = ({
      scope: scope
      tag: tag
    } for scope in @array) if tag

  # Public: Return the length of the scope array.
  #
  # Returns a {Number} representing the length of the scope array.
  length: ->
    @array.length

  # Public: Push a scope {String} onto a scope array.
  #
  # * `scope` A {String} containing the scope name.
  # * `tag` An object with `open` and `close` tag replace patterns.
  #
  # Returns a {String} with an opening scope tag.
  push: (scope, tag={}) ->
    @array.push({scope: scope, tag: tag})
    scope = replace(scope, tag.escape) if tag.escape?
    # We're trying to keep the syntax the same as the *first-mate* RegExp,
    # rather than using `$&` for the insertion, as would be the case with the
    # following:
    #     if tag.open? then scope.replace(/.*/, tag.open) else ''
    if tag.open? then tag.open.replace(/\\0/, scope) else ''

  # Public: Pop a scope off of a scope array.
  #
  # Returns a {String} with an closing scope tag.
  pop: ->
    return '' if not frame = @array.pop()
    frame.scope = replace(frame.scope, frame.tag.escape) if frame.tag?.escape?
    if frame.tag?.close? then frame.tag.close.replace(/\\0/, frame.scope) else ''

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
