view = new ldview do
  root: document.body

editor = new Quill view.get(\editor), do
  theme: 'snow'
  modules:
    toolbar:
      container: view.get(\toolbar)
      handlers:
        image: ->
          range = editor.getSelection true
          opt =
            src: '/assets/img/sample.jpg'
            mode: \auto
            width: \100%
            height: \120px
            fit: \cover
          opt = src: '/assets/img/sample.jpg', mode: \free, alt: \hello
          editor.insertEmbed range.index, 'image-plus', opt{src}, 'user'
          editor.formatText range.index, 1, opt
          editor.setSelection range.index + 1
