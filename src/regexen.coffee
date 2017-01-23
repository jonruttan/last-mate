# Public: Apply an array of RegExp search/replace expressions on a string.
#
# **NOTE:** We're trying to keep the syntax the same as the *first-mate* RegExp,
#           so we use `\\0` rather than using `$&` for the insertion of the
#           matched substring, and `\\n` for the *nth* parenthesized submatch
#           string.
#
# * `string` {String} to transform.
# * `regexen` {Array} of {Objects} containing a `pattern` to apply and a
#   `replace` expression.
#
# Returns a {String} with the tranformations applied.
module.exports =
replaceAll: (string, regexen) ->
  for regex in regexen
    string = string.replace new RegExp(regex.pattern, 'g'),
      regex.replace.replace(/\$/g, '$$$$')
        .replace(/\\0/g, '$$&')
        .replace(/\\(\d+)/g, '$$$1')

  string

