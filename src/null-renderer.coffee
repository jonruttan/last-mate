Renderer = require './renderer'

# A renderer with no patterns that is always available from a {RendererRegistry}
# even when it is completely empty.
module.exports =
class NullRenderer extends Renderer
  constructor: (registry) ->
    name = 'Null Renderer'
    scopeName = 'text.plain.null-renderer'
    super(registry, {name, scopeName})

  getScore: -> 0
