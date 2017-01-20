path = require 'path'
_ = require 'underscore-plus'
fs = require 'fs-plus'
TagStack = require '../lib/tag-stack'

describe "TagStack operations", ->
  describe "::constructor(@array=[], tag)", ->
    it "creates new objects with an empty stack", ->
      stack = new TagStack()
      expect(stack.array.length).toBe 0

    it "creates new objects with an initialized stack", ->
      stack = new TagStack({scope: i} for i in [1, 2, 3])
      expect(stack.array.length).toBe 3
      expect(stack.array[0].scope).toBe 1
      expect(stack.array[2].scope).toBe 3

    it "creates new objects with an initialized stack", ->
      stack = new TagStack([1, 2, 3], true)
      expect(stack.array.length).toBe 3
      expect(stack.array[0].scope).toBe 1
      expect(stack.array[2].scope).toBe 3

    it "creates new objects with an initialized stack", ->
      stack = new TagStack([1, 2, 3], {close: 'close'})
      expect(stack.array.length).toBe 3
      expect(stack.array[0].scope).toBe 1
      expect(stack.array[0].tag.close).toBe 'close'
      expect(stack.array[2].scope).toBe 3
      expect(stack.array[2].tag.close).toBe 'close'

  describe "::push(scope)", ->
    it "pushes a scope on the stack", ->
      stack = new TagStack()
      stack.push('scope')
      expect(stack.array.length).toBe 1
      expect(stack.array[0].scope).toBe 'scope'

    it "returns an empty string when no opening tag is provided", ->
      stack = new TagStack()
      tag = stack.push('scope')
      expect(stack.array.length).toBe 1
      expect(tag).toBe ''

    it "returns an opening tag when one is provided", ->
      stack = new TagStack()
      tag = stack.push('scope', {open: 'open'})
      expect(stack.array.length).toBe 1
      expect(tag).toBe 'open'

    it "returns an opening tag when one is provided", ->
      stack = new TagStack()
      tag = stack.push('scope', {open: 'open(\\0)'})
      expect(stack.array.length).toBe 1
      expect(tag).toBe 'open(scope)'

    it "returns an escaped opening tag with an injected scope when provided", ->
      stack = new TagStack()
      tag = stack.push('1.2', {open: 'open1(\\0)', escape: [{pattern: '\\.', replace: ' '}]})
      expect(stack.array.length).toBe 1
      expect(tag).toBe 'open1(1 2)'
      tag = stack.push('2-3', {open: 'open2(\\1)', escape: [{pattern: '-', replace: ' '}]})
      expect(stack.array.length).toBe 2
      expect(tag).toBe 'open2(1 2)'
      tag = stack.push('3 4', {open: 'open3(\\1)'})
      expect(stack.array.length).toBe 3
      expect(tag).toBe 'open3(2 3)'
      tag = stack.push('4 5', {open: 'open4(\\4)'})
      expect(stack.array.length).toBe 4
      expect(tag).toBe 'open4()'

  describe "::pop(scope)", ->
    it "pops a scope off the stack", ->
      stack = new TagStack()
      stack.push('scope')
      stack.pop()
      expect(stack.array.length).toBe 0

    it "returns an empty string when no closing tag was provided (by push)", ->
      stack = new TagStack()
      stack.push('scope')
      expect(stack.array.length).toBe 1
      tag = stack.pop()
      expect(stack.array.length).toBe 0
      expect(tag).toBe ''

    it "returns a closing tag when one is provided", ->
      stack = new TagStack()
      stack.push('scope', {close: 'close'})
      tag = stack.pop()
      expect(stack.array.length).toBe 0
      expect(tag).toBe 'close'

    it "returns a closing tag with an injected scope when one is provided", ->
      stack = new TagStack()
      stack.push('scope', {close: 'close(\\0)'})
      tag = stack.pop()
      expect(stack.array.length).toBe 0
      expect(tag).toBe 'close(scope)'

    it "returns an escaped closing tag when provided", ->
      stack = new TagStack()
      stack.push('1.2', {close: 'close1(\\0)', escape: [{pattern: '\\.', replace: ' '}]})
      stack.push('2-3', {close: 'close2(\\1)', escape: [{pattern: '-', replace: ' '}]})
      stack.push('3 4', {close: 'close3(\\1)'})
      stack.push('4 5', {close: 'close4(\\4)'})
      tag = stack.pop()
      expect(stack.array.length).toBe 3
      expect(tag).toBe 'close4()'
      tag = stack.pop()
      expect(stack.array.length).toBe 2
      expect(tag).toBe 'close3(2 3)'
      tag = stack.pop()
      expect(stack.array.length).toBe 1
      expect(tag).toBe 'close2(1 2)'
      tag = stack.pop()
      expect(stack.array.length).toBe 0
      expect(tag).toBe 'close1(1 2)'

  describe "::sync(current, desired)", ->
    xit 'pops excess frames off of the stack', ->
      stack = new TagStack([1,2,3])
      expect(stack.array.length).toBe 3
      stack.sync(new TagStack([1,2]))
      expect(stack.array.length).toBe 2
      stack.sync(new TagStack())
      expect(stack.array.length).toBe 0

    it 'pops excess frames off of the stack', ->
      stack = new TagStack({scope: "#{i}", tag: {close: "\\0"}} for i in [1, 2, 3])
      expect(stack.array.length).toBe 3
      tags = stack.sync(new TagStack({scope: "#{i}", tag: {close: "\\0"}} for i in [1, 2]))
      expect(stack.array.length).toBe 2
      expect(tags).toBe '3'
      tags = stack.sync(new TagStack())
      expect(stack.array.length).toBe 0
      expect(tags).toBe '21'

    it 'replaces frames', ->
      stack = new TagStack({scope: "#{i}", tag: {close: "\\0"}} for i in [1, 2, 3])
      expect(stack.array.length).toBe 3
      tags = stack.sync(new TagStack({scope: "#{i}", tag: {close: "\\0"}} for i in [1, 2, 4]))
      expect(stack.array.length).toBe 3
      expect(tags).toBe '3'
      tags = stack.sync(new TagStack({scope: "#{i}", tag: {close: "\\0"}} for i in [2, 2, 4]))
      expect(stack.array.length).toBe 3
      expect(tags).toBe '421'

    it 'pushes new frames', ->
      stack = new TagStack({scope: "#{i}", tag: {close: "\\0"}} for i in [1, 2, 3])
      expect(stack.array.length).toBe 3
      tags = stack.sync(new TagStack({scope: "#{i}", tag: {close: "\\0"}} for i in [1, 2, 3, 4]))
      expect(stack.array.length).toBe 4
      expect(tags).toBe ''
      tags = stack.sync(new TagStack({scope: "#{i}", tag: {close: "\\0"}} for i in [1, 2, 4, 5, 6]))
      expect(stack.array.length).toBe 5
      expect(tags).toBe '43'
