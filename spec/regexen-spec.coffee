regexen = require '../lib/regexen'

describe "regexen operations", ->
  describe "::replace(string, regexen)", ->
    it "replaces strings using patterns", ->
      string = regexen.replaceAll '123', [
        {pattern: '1', replace: 'a'}
        {pattern: /2/, replace: 'b'}
      ]
      expect(string).toBe 'ab3'

    it "replaces strings using patterns with matched substring insertions", ->
      string = regexen.replaceAll '123', [
        {pattern: '1', replace: 'a\\0a'}
        {pattern: '(2)', replace: 'b\\1b'}
      ]
      expect(string).toBe 'a1ab2b3'

    it "replaces strings using patterns escapes JavaScript RegExp $ patterns", ->
      string = regexen.replaceAll '123', [
        {pattern: '1', replace: 'a$&a'}
        {pattern: '(2)', replace: 'b$1b'}
      ]
      expect(string).toBe 'a$&ab$1b3'
