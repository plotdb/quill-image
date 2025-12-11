# Change Logs

## v0.0.7

 - dismiss caret when unbinding so caret won't be visible if editor is reused


## v0.0.6

 - add stretch and reset action
 - polling bounding box change to update resizer size
 - support alignment point assignment. toggled baed on fit mode
 - fallback to 100% width if user resize out of container width
 - use separated button for fit mode switching


## v0.0.5

 - support src update event


## v0.0.4

 - fix bug: sig undefined when setting image, due to incorrect variable name used


## v0.0.3

 - move alt and src from value to formats
 - ensure default value of background-repeat and background-size


## v0.0.2

 - remove duplicated and no effect code
 - fix bug: retoggle editor causes the image size to reset. This is because we apply formatting in creator, which should be done separatedly in formatter by quill.


## v0.0.1

 - init release
