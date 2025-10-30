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
          editor.insertEmbed range.index, 'image-plus', {src: '/assets/img/sample.jpg'}, 'user'
          editor.setSelection range.index + 1
