Embed = Quill.import \blots/embed
Delta = Quill.import \delta
fit2size = (v = '') -> if !v or v == \fill => "100% 100%" else v
attrname = (v) -> if v in <[width height alt]> => v else if v in <[key]> => "data-qip-#v" else "data-#v"
getfmt = ({node, name}) ->
  if name in <[width height mode alt src]> => return node.getAttribute(attrname name) or ''
  s = node.style
  if name == \fit => return if (v = s.backgroundSize) == "100% 100%" or v == \initial or !v => \fill else v
  if name == \repeat => return s.backgroundRepeat or 'repeat'

setfmt = ({node, name: n, value: v}) ->
  if n in <[mode]> and !v => v = {mode: 'free'}[n]
  if n in <[width height mode alt]>
    if v? => node.setAttribute attrname(n), v
    else node.removeAttribute attrname(n)
  else if n in <[fit]> => node.style.backgroundSize = fit2size v
  else if n in <[repeat]> => node.style.backgroundRepeat = v or 'no-repeat'
  else if n in <[src]> =>
    node.setAttribute attrname(n), v
    node.style.backgroundImage = "url(#v)"
  # TODO this causes exception. not sure if we do need it or we can remove?
  #else Embed.call @, n, v

image-plus-blot = -> Reflect.construct Embed, arguments, image-plus-blot
image-plus-blot.prototype = Object.create Embed.prototype
image-plus-blot.prototype.constructor = image-plus-blot
image-plus-blot.prototype <<<
  format: (n, v) -> setfmt ({node: @domNode, name: n, value: v})

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

  @_.dom.button = n = document.createElement \div
  @_.dom.base.appendChild n
  n.classList.add \quill-image-plus-button

  @_.dom.button.innerHTML = """
  <div data-action="src"><svg xmlns="http://www.w3.org/2000/svg" width="12px" viewBox="0 0 1200 1200"><path d="M1099.8 345.4v-.4a49.8 49.8 0 0 0-9.4-24.6c-.1 0-.2 0-.2-.2l-1.2-1.5-.4-.4-1.2-1.4-.4-.5a50 50 0 0 0-1.6-1.8l-300-300-1.8-1.6-.5-.4-1.4-1.2-.4-.4-1.5-1.2c-.1 0-.2 0-.3-.2l-1.8-1.2A49.7 49.7 0 0 0 755 .2h-.4A50.3 50.3 0 0 0 750 0H150a50 50 0 0 0-50 50v1100a50 50 0 0 0 50 50h900a50 50 0 0 0 50-50V350a49.7 49.7 0 0 0-.2-4.6zM800 170.7 929.3 300H800V170.7zM200 1100V100h500v250a50 50 0 0 0 50 50h250v700H200z"/></svg></div>
  <div data-action="fit"><svg xmlns="http://www.w3.org/2000/svg" width="12px" viewBox="0 0 1200 1200"><path d="M1100 50H100a50 50 0 0 0-50 50v1000a50 50 0 0 0 50 50h1000a50 50 0 0 0 50-50V100a50 50 0 0 0-50-50zm-50 1000H150V150h900v900zM350 900h500a50 50 0 0 0 50-50V350a50 50 0 0 0-50-50H350a50 50 0 0 0-50 50v500a50 50 0 0 0 50 50zm50-500h400v400H400V400z"/></svg></div>
  """

  @_.dom.button.addEventListener \mousedown, (evt) -> evt.stopPropagation!
  @_.dom.button.addEventListener \mouseup, (evt) -> evt.stopPropagation!
  @_.dom.button.addEventListener \click, (evt) ~>
    evt.stopPropagation!
    if !(tgt = evt.target.closest('.quill-image-plus-button > div[data-action]')) => return
    action = tgt.dataset.action
    switch action
    | \src => # TODO
    | \fit =>
      if !(blot = Quill.find @_.tgt.node) => return
      quill = @_.editor
      index = quill.getIndex blot
      f = quill.getFormat index, 1
      cur = f.fit or \fill
      cycle = <[fill cover contain]>
      i = cycle.indexOf cur
      next = cycle[(i + 1) % cycle.length]
      quill.formatText index, 1, {fit: next}
      @bind @_.tgt{node, key}

  move-handler = (evt) ~>
    evt.stopPropagation!
    if !@_.start or !evt.buttons =>
      window.removeEventListener \mousemove, move-handler
      window.removeEventListener \mouseup, move-handler
      document.body.classList.toggle \quill-image-plus-select-suppress, false
      if !@_.preview-pos => return
      n = @_.editor.container.querySelector("[data-qip-key='#{@_.tgt?key}']")
      blot = Quill.find(n)
      index = @_.editor.get-index(blot)
      @_.editor.formatText index, 1, @_.preview-pos{width, height}
      # alternative
      # @_.editor.updateContents ops: [{retain: index}, {retain: 1, attributes: @_.preview-pos{width, height}}]
      return @bind {node: n, key: @_.tgt?key}
    [x, y, dir, free] = [evt.clientX, evt.clientY, @_.dir, evt.altKey]
    [dx, dy] = [x - @_.x, y - @_.y]
    [w,h] = [@_.pos.width, @_.pos.height]
    if /n/.exec(dir) => dy = -dy
    if /w/.exec(dir) => dx = -dx

    if !free =>
      if !@_.resize-based-axis => @_.resize-based-axis = if Math.abs(dx) > Math.abs(dy) => \x else \y
      [dx, dy] = if @_.resize-based-axis == \x => [dx, dx * h/w] else [dy * w/h, dy]
    {x, y, width, height} = @_.pos
    if /n/.exec(dir) => [y, height] = [@_.pos.y - dy, @_.pos.height + dy]
    if /s/.exec(dir) => [y, height] = [@_.pos.y, @_.pos.height + dy]
    if /w/.exec(dir) => [x, width] = [@_.pos.x - dx, @_.pos.width + dx]
    if /e/.exec(dir) => [x, width] = [@_.pos.x, @_.pos.width + dx]

    @repos {x, y, width, height, preview: true, mode: getfmt({node: @_.tgt?node, name: \mode})}

  @_.dom.base.addEventListener \mousedown, (evt) ~>
    dir = <[nw ne se sw n s w e]>.filter((t) ~> @_.dom[t] == evt.target).0
    if !dir => return
    @_.start = true
    @_ <<< {x: evt.clientX, y: evt.clientY, dir, resize-based-axis: null}
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
    @_.tgt = {key, node}
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
    @repos {x, y, width, height, mode: getfmt({node, name: \mode})}
  repos: ({x, y, width, height, preview, mode = \free}) ->
    if width < 0 => [x,width] = [x + width, -width]
    if height < 0 => [y,height] = [y + height, -height]
    if !preview => @_.{}pos <<< {x, y, width, height}
    else @_.{}preview-pos <<< {x, y, width, height}
    node-size = 8
    bar-size = 1
    width = Math.floor(width)
    height = Math.floor(height)
    [
      [\nw, x, y]
      [\ne, x + width - node-size, y]
      [\se, x + width - node-size, y + height - node-size]
      [\sw, x, y + height - node-size]
    ].map ([t, x, y]) ~>
      @_.dom[t].style <<<
        transform: "translate(#{Math.floor x}px, #{Math.floor y}px)"
        display: if mode != \auto => \block else \none
    [
      [\n, x, y, width, 0]
      [\e, x + width - bar-size, y, 0, height]
      [\s, x, y + height - bar-size, width, 0]
      [\w, x, y, 0, height]
    ].map ([t, x, y, width, height]) ~>
      @_.dom[t].style <<<
        transform: "translate(#{Math.floor x}px, #{Math.floor y}px)"
        width: "#{Math.floor width or bar-size}px"
        height: "#{Math.floor height or bar-size}px"
        display: if mode != \auto => \block else \none
    @_.dom.button.style <<<
      transform: "translate(#{Math.floor x + node-size}px, #{Math.floor y + node-size}px)"

image-plus-blot <<< Embed <<<
  blotName: 'image-plus'
  tagName: 'img'
  create: (opt = {}) ->
    if !image-plus-blot.resizer => image-plus-blot.resizer = new resizer!
    node = Embed.create.call @, opt
    node._ = lc = opt: {}
    # we use img tag but background style to render, and src is used to present a 1px transparent gif.
    # thus we can't use src to store the real src - instead we use data-src.
    node.setAttribute \src, "data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs="
    node.setAttribute attrname(\src), opt.src
    node.style <<<
      background: "url(#{opt.src})"
      backgroundColor: 'rgba(0,0,0,.8)'
      backgroundPosition: 'center center'
      backgroundSize: '100% 100%' # default value since if no fit in formats it will not be set
    node.setAttribute \data-qip-key, key = (opt.key or "quill-image-plus-#{Math.random!toString(36)substring(2)}")
    lc.img =
      ref: null
      loading: true
    lc.promise = new Promise (res, rej) ->
      lc.img.ref = img = new Image!
      img.onload = ->
        lc.img.loading = false
        lc.img <<< {width: img.naturalWidth, height: img.naturalHeight}
        [w,h] = [node.getAttribute(\width), node.getAttribute(\height)]
        if !w? => setfmt {node, name: \width, value: lc.img.width}
        if !h? => setfmt {node, name: \height, value: lc.img.height}
      img.onerror = -> lc.img.loading = false
      img.src = opt.src
    window.addEventListener \mouseup, -> image-plus-blot.resizer.unbind!
    node.setAttribute \draggable, false
    node.addEventListener \mouseup, (evt) -> evt.stopPropagation!
    node.addEventListener \mousedown, (evt) ->
      image-plus-blot.resizer.bind {node, key, evt}
      move-handler = (evt) ~>
        if evt.buttons =>
          node._.dragging = true
          return image-plus-blot.resizer.caret {node, evt}
        window.removeEventListener \mousemove, move-handler
        window.removeEventListener \mouseup, move-handler
        if !node._.dragging => return
        node._.dragging = false
        if !(position = document.caretPositionFromPoint evt.clientX, evt.clientY) => return
        box = node.getBoundingClientRect!
        # drag to some strange place: .ql-editor null
        if !node.closest('.ql-editor') => return
        # single click trigger something like moving after itself
        quill = Quill.find node.closest('.ql-editor').parentElement
        old-blot = Quill.find node
        old-index = quill.getIndex old-blot
        get-blot = ({offsetNode: n, offset: idx}) ->
          if n.nodeName != \#text and n.childNodes? => [n,idx] = [n.childNodes[idx <? (n.childNodes - 1)], 0]
          blot = Quill.find n, true
          index = if !blot => 0 else quill.get-index(blot) + idx
          return {blot, index}
        {blot: new-blot, index: new-index} = get-blot position
        # drag outside - no new-blot
        if !new-blot => return
        fmts = old-blot.formats!
        if new-index > old-index => new-index -= 1
        if new-index == old-index => return
        delta = new Delta!retain(old-index <? new-index)
        # we don't use `node{src}` below because it will be the 1px gif.
        delta = if old-index < new-index => delta.delete(1)
        else if old-index > new-index => delta.insert(
          {'image-plus': {} <<< { transient: true } <<< (
            Object.fromEntries(<[src key]>.map (t) -> [t, node.getAttribute(attrname t)])
          )},
          fmts
        ) else delta
        delta = delta.retain(Math.abs(new-index - old-index))
        delta = if old-index > new-index => delta.delete(1)
        else if old-index < new-index => delta.insert(
          {'image-plus': {} <<< {transient: true } <<< (
            Object.fromEntries(<[src key]>.map (t) -> [t, node.getAttribute(attrname t)])
          )},
          fmts
        ) else delta
        quill.updateContents delta
        image-plus-blot.resizer.dismiss-caret!

      window.addEventListener \mousemove, move-handler
      window.addEventListener \mouseup, move-handler
    if opt.transient => node.onload = -> image-plus-blot.resizer.bind {node, key}
    return node
  value: (n) -> Object.fromEntries( <[src key]> .map (t) -> [t, n.getAttribute attrname t])
  formats: (node) ->
    Object.fromEntries <[width height mode fit repeat alt src]>.map (name) -> [name, getfmt {node, name}]

Quill.register image-plus-blot
