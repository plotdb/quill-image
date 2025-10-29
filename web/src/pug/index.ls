# Initialize Quill editor with image tools
quill = null
image-tools = null
debug-element = null

init = ->
    debug-element = document.querySelector('#debug-info')
    
    # Initialize Quill editor
    quill := new Quill('#editor', {
        theme: 'snow'
        modules: {
            toolbar: [
                ['bold', 'italic', 'underline']
                ['link', 'image']
                [{ 'list': 'ordered'}, { 'list': 'bullet' }]
                ['clean']
            ]
        }
    })
    
    # Initialize our image tools module
    image-tools := new window.quill-image-tools(quill)
    
    log-debug("Quill editor initialized")
    log-debug("Image tools module loaded")
    
    setup-test-buttons!
    setup-quill-events!

setup-test-buttons = ->
    # Insert test image button
    insert-btn = document.querySelector('#insert-image')
    insert-btn.addEventListener('click', ->
        # Insert a test image using Quill's API
        index = quill.getSelection()?.index || quill.getLength! - 1
        
        # Use a placeholder image service for testing
        test-image-url = 'https://picsum.photos/300/200?random=' + Date.now!
        
        quill.insertEmbed(index, 'image', test-image-url)
        log-debug("Inserted test image at index #{index}")
    )
    
    # Toggle readonly button
    readonly-btn = document.querySelector('#toggle-readonly')
    readonly-btn.addEventListener('click', ->
        is-readonly = quill.isEnabled!
        if is-readonly
            quill.disable!
            readonly-btn.textContent = 'Enable Editor'
            log-debug("Editor disabled")
        else
            quill.enable!
            readonly-btn.textContent = 'Disable Editor'
            log-debug("Editor enabled")
    )

setup-quill-events = ->
    # Monitor Quill content changes for debugging
    quill.on('text-change', (delta, old-delta, source) ->
        log-debug("Text changed (source: #{source})")
        if delta.ops?
            for op in delta.ops
                if op.insert?.image?
                    log-debug("Image inserted: #{op.insert.image}")
                if op.attributes?
                    log-debug("Attributes applied: #{JSON.stringify(op.attributes)}")
    )
    
    # Monitor selection changes
    quill.on('selection-change', (range, old-range, source) ->
        if range?
            log-debug("Selection: #{range.index}-#{range.index + range.length}")
        else
            log-debug("Selection cleared")
    )

log-debug = (message) ->
    timestamp = new Date!.toLocaleTimeString!
    if debug-element?
        debug-element.textContent += "#{timestamp}: #{message}\n"
        debug-element.scrollTop = debug-element.scrollHeight
    console.log("[QuillImageTest] #{message}")

# Start when DOM is ready
if document.readyState is 'loading'
    document.addEventListener('DOMContentLoaded', init)
else
    init!
