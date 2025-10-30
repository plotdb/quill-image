BlockEmbed = Quill.import('blots/block/embed')

image-plus-blot = -> Reflect.construct BlockEmbed, arguments, image-plus-blot
image-plus-blot.prototype = Object.create BlockEmbed.prototype
image-plus-blot.prototype.constructor = image-plus-blot
Object.setPrototypeOf image-plus-blot, BlockEmbed

image-plus-blot <<< BlockEmbed <<<
  blotName: 'image-plus'
  tagName: 'img'
  create: (v) ->
    node = BlockEmbed.create.call @, v
    node.setAttribute \src, v.src
    node.setAttribute \alt, v.alt or ''
    if v.width => node.setAttribute \width, v.width
    if v.height => node.setAttribute \height, v.height
    return node
  value: (n) -> <[src alt width height]>.map (t) -> [t, n.getAttribute(t)]

Quill.register image-plus-blot
