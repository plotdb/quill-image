quill-image-tools = (quill, options = {}) ->
    @ <<<
        quill: quill
        root: quill.root
        is-active: false
        selected-image: null
        overlay: null
        resize-handles: {}
        drag-state: null
        _opt: options
    
    @ <<< options
    
    @init!
    @

quill-image-tools.prototype = Object.create(Object.prototype) <<<
    constructor: quill-image-tools
    
    init: ->
        @setup-styles!
        @setup-events!
        @register-module!
    
    setup-styles: ->
        # Create styles for overlay and handles
        return if document.query-selector('#quill-image-tools-styles')
        
        style = document.create-element('style')
        style.id = 'quill-image-tools-styles'
        style.innerHTML = '''
            .quill-image-overlay {
                position: absolute;
                border: 2px solid #0066cc;
                pointer-events: none;
                z-index: 1000;
                box-sizing: border-box;
            }
            
            .quill-image-handle {
                position: absolute;
                width: 12px;
                height: 12px;
                background: #0066cc;
                border: 2px solid white;
                border-radius: 2px;
                pointer-events: auto;
                cursor: nw-resize;
                box-sizing: border-box;
            }
            
            .quill-image-handle.se { 
                bottom: -6px; 
                right: -6px; 
                cursor: se-resize; 
            }
            
            .quill-image-handle.sw { 
                bottom: -6px; 
                left: -6px; 
                cursor: sw-resize; 
            }
            
            .quill-image-handle.ne { 
                top: -6px; 
                right: -6px; 
                cursor: ne-resize; 
            }
            
            .quill-image-handle.nw { 
                top: -6px; 
                left: -6px; 
                cursor: nw-resize; 
            }
            
            .quill-image-dragging {
                opacity: 0.5;
                pointer-events: none;
            }
        '''
        document.head.append-child(style)
    
    setup-events: ->
        # Use document-level events to handle mouse move/up anywhere
        # This prevents losing drag state when cursor moves outside editor
        @root.add-event-listener('click', (e) ~> @on-editor-click.apply(@, [e]))
        document.add-event-listener('mousedown', (e) ~> @on-mouse-down.apply(@, [e]))
        document.add-event-listener('mousemove', (e) ~> @on-mouse-move.apply(@, [e]))
        document.add-event-listener('mouseup', (e) ~> @on-mouse-up.apply(@, [e]))
        
        # Handle escape key to deselect
        document.add-event-listener('keydown', (e) ~> @on-keydown.apply(@, [e]))
    
    register-module: ->
        # Register with Quill as a module for proper integration
        if @quill.register?
            @quill.register('modules/imageTools', quill-image-tools)
    
    on-editor-click: (e) ~>
        target = e.target
        
        # Check if clicked on an image
        if target.tag-name is 'IMG'
            e.prevent-default!
            @select-image(target)
        else
            # Click outside image, deselect
            @deselect-image!
    
    on-keydown: (e) ~>
        if e.key is 'Escape'
            @deselect-image!
    
    on-mouse-down: (e) ~>
        return unless @overlay?
        
        # Check if mousedown on a resize handle
        if e.target.class-list.contains('quill-image-handle')
            e.prevent-default!
            @start-resize(e)
        else if e.target is @selected-image
            # Start drag for reordering
            e.prevent-default!
            @start-drag(e)
    
    on-mouse-move: (e) ~>
        if @drag-state?.type is 'resize'
            @handle-resize(e)
        else if @drag-state?.type is 'drag'
            @handle-drag(e)
    
    on-mouse-up: (e) ~>
        if @drag-state?
            @finish-drag(e)
    
    select-image: (img) ->
        @deselect-image!
        
        @selected-image = img
        @is-active = true
        @create-overlay!
        @position-overlay!
    
    deselect-image: ->
        return unless @is-active
        
        @is-active = false
        @selected-image = null
        @remove-overlay!
    
    create-overlay: ->
        return unless @selected-image?
        
        # Create overlay container
        @overlay = document.create-element('div')
        @overlay.class-name = 'quill-image-overlay'
        
        # Create resize handles
        corners = ['nw', 'ne', 'sw', 'se']
        for corner in corners
            handle = document.create-element('div')
            handle.class-name = "quill-image-handle #{corner}"
            handle.dataset.corner = corner
            @overlay.append-child(handle)
            @resize-handles[corner] = handle
        
        # Add to document
        document.body.append-child(@overlay)
    
    remove-overlay: ->
        return unless @overlay?
        
        @overlay.remove!
        @overlay = null
        @resize-handles = {}
    
    position-overlay: ->
        return unless @overlay? and @selected-image?
        
        rect = @selected-image.get-bounding-client-rect!
        
        @overlay.style <<<
            left: "#{rect.left}px"
            top: "#{rect.top}px"
            width: "#{rect.width}px"
            height: "#{rect.height}px"
    
    start-resize: (e) ->
        corner = e.target.dataset.corner
        rect = @selected-image.get-bounding-client-rect!
        
        @drag-state =
            type: 'resize'
            corner: corner
            start-x: e.client-x
            start-y: e.client-y
            start-width: rect.width
            start-height: rect.height
            aspect-ratio: rect.width / rect.height
    
    handle-resize: (e) ->
        return unless @drag-state?.type is 'resize'
        
        {corner, start-x, start-y, start-width, start-height, aspect-ratio} = @drag-state
        
        dx = e.client-x - start-x
        dy = e.client-y - start-y
        
        new-width = start-width
        new-height = start-height
        
        switch corner
        | 'se' =>
            new-width = start-width + dx
            new-height = new-width / aspect-ratio
        | 'sw' =>
            new-width = start-width - dx
            new-height = new-width / aspect-ratio
        | 'ne' =>
            new-width = start-width + dx
            new-height = new-width / aspect-ratio
        | 'nw' =>
            new-width = start-width - dx
            new-height = new-width / aspect-ratio
        
        # Apply minimum size constraints
        new-width = Math.max(50, new-width)
        new-height = new-width / aspect-ratio
        
        # Update image size temporarily for preview
        @selected-image.style <<<
            width: "#{new-width}px"
            height: "#{new-height}px"
        
        @position-overlay!
    
    start-drag: (e) ->
        # TODO: Implement drag-to-reorder functionality
        @drag-state =
            type: 'drag'
            start-x: e.client-x
            start-y: e.client-y
    
    handle-drag: (e) ->
        # TODO: Implement drag preview and drop target detection
        return unless @drag-state?.type is 'drag'
    
    finish-drag: (e) ->
        return unless @drag-state?
        
        if @drag-state.type is 'resize'
            @finish-resize!
        else if @drag-state.type is 'drag'
            @finish-reorder!
        
        @drag-state = null
    
    finish-resize: ->
        # Apply final size through Quill Delta operations
        return unless @selected-image?
        
        new-width = parse-int(@selected-image.style.width)
        new-height = parse-int(@selected-image.style.height)
        
        # Get image's position in Quill content
        blot = @quill.scroll.find(@selected-image)
        return unless blot?
        
        index = @quill.get-index(blot)
        
        # Update through Delta for proper undo/redo support
        @quill.format-text(index, 1, {
            width: "#{new-width}px"
            height: "#{new-height}px"
        })
        
        @position-overlay!
    
    finish-reorder: ->
        # TODO: Implement reorder through Delta operations
        console.log('Drag reorder finished - not yet implemented')
    
    destroy: ->
        @deselect-image!
        # Remove event listeners for cleanup
        # Note: In real implementation, would store bound functions to remove properly

# Cross-environment export
if window?
    window.quill-image-tools = quill-image-tools
else
    module.exports = quill-image-tools
