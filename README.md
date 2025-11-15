# quill-image-plus


possible options:

 - mode: define how size is decided
   - `free`: free mode. default value. user can resize image in both direction freely.
   - `auto`: auto mode. image size is decided automatically based on parent size.
 - aspectRatio: define image aspect ratio
   - `native`: ratio determined based on the original image. default value.
     - with mode `auto` + aspectRatio `native`, longest side should fit into parent.
   - `custom`: customizable ratio. user an adjust either width or height freely.
     - fit: how the original image should fit into current frame.
       - `fill`: stretch width and height regardless of image's original aspect ratio. default value
       - `contain`: fit longest side into container
       - `cover`: cover the entire container by enlarging image if necessary.
 - (TBD) background: only if fit = contain or there is margin.
   - color: background color with alpha channel
 - (TBD) margin: margin between container and image.
 - (TBD) align: only if fit is either `contain` or `cover`.
   - vertical: `top` / `middle` / `bottom`. default `middle`
   - horizontal: `left` / `middle` / `right`. default `middle`

## Aspect Ratio

Hold Option/Alt while resizing to unlock freeform scaling.

