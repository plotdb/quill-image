# quill-image-plus

Quill's image blot.


## Usage

Insert an image with Quill editor instance. For example, this following Quill editor instance, a handler for inserting image is defined on toolbar:

    editor = new Quill(root, {
      modules: toolbar:
        container: toolbarNode
        handlers: image: ->
          range = editor.getSelection true
          options = { ... }
          editor.insertEmbed range.index, 'image-plus', options, 'user'
          editor.setSelection range.index + 1
    })

where `options` contains following fields:

 - `key`: unique key for refer to this image. optional, randomly generated when omitted.
 - `src`: image src url.
 - `width`, `height`: width and height of this image. can be `px` or `%`. optional.
   - when omitted, automatically deducted from image natural size.`
 - mode: define how size is decided
   - `free`: free mode. default value. user can resize image in both direction freely.
   - `auto`: auto mode. image size is decided automatically based on parent size.
     - user can't resize under this mode.
 - `fit`: indicate how the original image should fit into image blot embed container.
   - `fill`: stretch width and height regardless of image's original aspect ratio. default value
   - `contain`: fit longest side into container
   - `cover`: cover the entire container by enlarging image if necessary.
 - (TBD) `aspectRatio`: define image aspect ratio
   - `native`: ratio determined based on the original image. default value.
     - with mode `auto` + aspectRatio `native`, longest side should fit into parent.
   - `custom`: customizable ratio. user an adjust either width or height freely.
 - (TBD) background: only if fit = contain or there is margin.
   - color: background color with alpha channel
 - (TBD) margin: margin between container and image.
 - (TBD) align: only if fit is either `contain` or `cover`.
   - vertical: `top` / `middle` / `bottom`. default `middle`
   - horizontal: `left` / `middle` / `right`. default `middle`


## User Interface Tips

 - Hold Option/Alt while resizing to unlock freeform scaling.

