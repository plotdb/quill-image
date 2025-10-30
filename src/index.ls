BlockEmbed = Quill.import('blots/block/embed')

image-plus-blot = -> Reflect.construct BlockEmbed, arguments, image-plus-blot
image-plus-blot.prototype = Object.create BlockEmbed.prototype
image-plus-blot.prototype.constructor = image-plus-blot
Object.setPrototypeOf image-plus-blot, BlockEmbed

resizer = ->
  @_ = dom: {}
  @_.dom.base = document.createElement \div
  @_.dom <<< Object.fromEntries <[n e s w]>.map (t) ~>
    n = document.createElement \div
    @_.dom.base.appendChild n
    n.classList.add(
      \quill-image-plus-resizer-bar,
      "quill-image-plus-resizer-bar-#{if t in <[n s]> => 'horizontal' else 'vertical'}"
    )
    [t, n]

  @_.dom <<< Object.fromEntries <[nw ne se sw]>.map (t) ~>
    n = document.createElement \div
    @_.dom.base.appendChild n
    n.classList.add \quill-image-plus-resizer-dot
    [t, n]
  @

resizer.prototype = Object.create(Object.prototype) <<<
  init: ->

image-plus-blot <<< BlockEmbed <<<
  blotName: 'image-plus'
  tagName: 'img'
  create: (v) ->
    if !image-plus-blot.resizer => image-plus-blot.resizer = new resizer!
    node = BlockEmbed.create.call @, v
    node.setAttribute \src, v.src
    node.setAttribute \alt, v.alt or ''
    if v.width => node.setAttribute \width, v.width
    if v.height => node.setAttribute \height, v.height
    return node
  value: (n) -> <[src alt width height]>.map (t) -> [t, n.getAttribute(t)]

Quill.register image-plus-blot
