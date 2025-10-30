Embed = Quill.import \blots/embed
Delta = Quill.import \delta

image-plus-blot = -> Reflect.construct Embed, arguments, image-plus-blot
image-plus-blot.prototype = Object.create Embed.prototype
image-plus-blot.prototype.constructor = image-plus-blot
image-plus-blot.prototype <<<
  format: (n, v) ->
    if n in <[width height]>
      if v? => @domNode.setAttribute n, v
      else @domNode.removeAttribute n
    else Embed.call @, n, v

Object.setPrototypeOf image-plus-blot, Embed

resizer = ->
  @_ = dom: {}
  @_.dom.caret = document.createElement \div
  @_.dom.caret.classList.add \quill-image-plus-resizer-caret
  @_.dom.base = document.createElement \div
  @_.dom.base.classList.add \quill-image-plus-resizer-root
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
  move-handler = (evt) ~>
    evt.stopPropagation!
    if !@_.start or !evt.buttons =>
      window.removeEventListener \mousemove, move-handler
      window.removeEventListener \mouseup, move-handler
      document.body.classList.toggle \quill-image-plus-select-suppress, false
      n = @_.editor.container.querySelector("[key='#{@_.key}']")
      blot = Quill.find(n)
      index = @_.editor.get-index(blot)
      @_.editor.formatText index, 1, @_.preview-pos{width, height}
      @_.editor.updateContents({
        ops: [
          {retain: index},
          {retain: 1, attributes: @_.preview-pos{width, height}}
        ]
      })
      return @bind {node: n, key: @_.key}
    [x, y, dir] = [evt.clientX, evt.clientY, @_.dir]
    [dx, dy] = [x - @_.x, y - @_.y]
    [w,h] = [@_.pos.width, @_.pos.height]
    if /n/.exec(dir) => dy = -dy
    if /w/.exec(dir) => dx = -dx
    [dx, dy] = if Math.abs(dx) > Math.abs(dy) => [dx, dx * h/w] else [dy * w/h, dy]
    {x, y, width, height} = @_.pos
    if /n/.exec(dir) => [y, height] = [@_.pos.y - dy, @_.pos.height + dy]
    if /s/.exec(dir) => [y, height] = [@_.pos.y, @_.pos.height + dy]
    if /w/.exec(dir) => [x, width] = [@_.pos.x - dx, @_.pos.width + dx]
    if /e/.exec(dir) => [x, width] = [@_.pos.x, @_.pos.width + dx]

    @repos {x, y, width, height, preview: true}

  @_.dom.base.addEventListener \mousedown, (evt) ~>
    dir = <[nw ne se sw n s w e]>.filter((t) ~> @_.dom[t] == evt.target).0
    if !dir => return
    @_.start = true
    @_ <<< {x: evt.clientX, y: evt.clientY, dir}
    document.body.classList.toggle \quill-image-plus-select-suppress, true
    window.addEventListener \mousemove, move-handler
    window.addEventListener \mouseup, move-handler
  @

resizer.prototype = Object.create(Object.prototype) <<<
  dismiss-caret: -> if @_.dom.caret.parentNode => @_.dom.caret.parentNode.removeChild @_.dom.caret
  caret: ({node, evt}) ->
    [x, y] = [evt.clientX, evt.clientY]
    container = node.closest('.ql-container')
    if !(position = document.caretPositionFromPoint x, y) => return
    if @_.dom.caret.parentNode => @_.dom.caret.parentNode.removeChild @_.dom.caret
    container.appendChild @_.dom.caret
    range = document.createRange!
    range.setStart position.offsetNode, position.offset
    range.setEnd position.offsetNode, position.offset
    box = range.getBoundingClientRect!
    rbox = container.getBoundingClientRect!
    [x, y] = [box.x - rbox.x, box.y - rbox.y]
    @_.dom.caret.style <<< left: "#{x}px", top: "#{y}px"
  unbind: -> @_.dom.base.style.display = \none
  bind: ({node, key, evt}) ->
    @_.dom.base.style.display = \block
    @_.key = key
    if evt and !@_.editor =>
      container = evt.target.closest('.ql-container')
      @_.editor = quill = Quill.find evt.target.closest('.ql-editor').parentElement
      @_.editor.on \text-change, ~> @unbind!
    else
      quill = @_.editor
      container = quill.container
    if @_.dom.base.parentNode => @_.dom.base.parentNode.removeChild @_.dom.base
    container.appendChild @_.dom.base
    rbox = container.getBoundingClientRect!
    box = node.getBoundingClientRect!
    [x, y, width, height] = [box.x - rbox.x, box.y - rbox.y, box.width ,box.height]
    @repos {x, y, width, height}
  repos: ({x, y, width, height, preview}) ->
    if !preview => @_.{}pos <<< {x, y, width, height}
    else @_.{}preview-pos <<< {x, y, width, height}
    [
      [\nw, x, y]
      [\ne, x + width - 8, y]
      [\se, x + width - 8, y + height - 8]
      [\sw, x, y + height - 8]
    ].map ([t, x, y]) ~> @_.dom[t].style <<< transform: "translate(#{x}px, #{y}px)"
    [
      [\n, x, y, width, 0]
      [\e, x + width - 3, y, 0, height]
      [\s, x, y + height - 3, width, 0]
      [\w, x, y, 0, height]
    ].map ([t, x, y, width, height]) ~>
      @_.dom[t].style <<<
        transform: "translate(#{x}px, #{y}px)"
        width: "#{width or 3}px"
        height: "#{height or 3}px"

image-plus-blot <<< Embed <<<
  blotName: 'image-plus'
  tagName: 'img'
  create: (v = {}) ->
    if !image-plus-blot.resizer => image-plus-blot.resizer = new resizer!
    node = Embed.create.call @, v
    node.setAttribute \src, v.src
    node.setAttribute \alt, (v.alt or '')
    node.setAttribute \key, key = (v.key or Math.random!toString(36)substring(2))
    v <<< width: 200, height: 300
    if v.width => node.setAttribute \width, v.width
    if v.height => node.setAttribute \height, v.height
    window.addEventListener \mouseup, -> image-plus-blot.resizer.unbind!
    node.setAttribute \draggable, false
    node.addEventListener \mouseup, (evt) -> evt.stopPropagation!
    node.addEventListener \mousedown, (evt) ->
      image-plus-blot.resizer.bind {node, key, evt}
      move-handler = (evt) ~>
        if evt.buttons =>
          return image-plus-blot.resizer.caret {node, evt}
        window.removeEventListener \mousemove, move-handler
        window.removeEventListener \mouseup, move-handler
        if !(position = document.caretPositionFromPoint evt.clientX, evt.clientY) => return
        box = node.getBoundingClientRect!
        # current pos. used to prevent small movement which leads to strange behavior with quick click
        pos2 = document.caretPositionFromPoint box.x, box.y
        if !pos2 => return
        # drag to some strange place: .ql-editor null
        if !node.closest('.ql-editor') => return
        # single click trigger something like moving after itself
        if pos2.offsetNode == position.offsetNode and pos2.offset == position.offset - 1 => return
        quill = Quill.find node.closest('.ql-editor').parentElement
        old-blot = Quill.find node
        old-index = quill.getIndex old-blot
        new-blot = Quill.find position.offsetNode, true
        # drag outside - no new-blot
        if !new-blot => return
        new-index = quill.getIndex(new-blot) + position.offset
        {width, height} = old-blot.formats!
        if position.offsetNode instanceof Element =>
          if (n = position.offsetNode.childNodes[position.offset]) == node => return
        if new-index > old-index => new-index -= 1
        #if Math.abs(new-index - old-index) < 1 => return
        delta = new Delta!retain(old-index <? new-index)
        delta = if old-index < new-index => delta.delete(1)
        else delta.insert(
          {'image-plus': node{src, alt, key, width, height} <<< {transient: true}},
          {width, height}
        )
        delta = delta.retain(Math.abs(new-index - old-index))
        delta = if old-index > new-index => delta.delete(1)
        else delta.insert(
          {'image-plus': node{src, alt, key, width, height} <<< {transient: true}}
          {width, height}
        )
        quill.updateContents delta
        image-plus-blot.resizer.dismiss-caret!

      window.addEventListener \mousemove, move-handler
      window.addEventListener \mouseup, move-handler
    if v.transient => node.onload = -> image-plus-blot.resizer.bind {node, key}
    return node
  value: (n) -> Object.fromEntries <[src alt width height key]>.map (t) -> [t, n.getAttribute(t)]
  formats: (node) -> formats = Object.fromEntries <[width height]>.map (t) -> [t, node.getAttribute(t) or '']

Quill.register image-plus-blot
