"""
Adds the Mouse.Position event via GLFW
"""
function add!(events, ::Type{Mouse.Position})
    @needs events: window = Window
    window = events[Window]
    GLFW.SetCursorPosCallback(window, (window, x, y) -> begin
        events[Mouse.Position] = (x, y)
    end)
    return
end

"""
Adds the Mouse.Scroll event via GLFW
"""
function add!(events, ::Type{Mouse.Scroll})
    @needs events: window = Window
    window = events[Window]
    GLFW.SetScrollCallback(window, (window, xoffset, yoffset) -> begin
        events[Mouse.Scroll] = (xoffset, yoffset)
    end)
    return
end

"""
Adds the Mouse.Buttons event via GLFW
"""
function add!(events, ::Type{Mouse.Buttons})
    @needs events: window = Window
    GLFW.SetMouseButtonCallback(window, (window, button, action, mods) -> begin
        set = events[Mouse.Buttons]
        button_enum = Mouse.Button(button)
        if button != GLFW.KEY_UNKNOWN
            if action == GLFW.PRESS
                push!(set, button_enum)
            elseif action == GLFW.RELEASE
                delete!(set, button_enum)
            elseif action == GLFW.REPEAT
                # nothing needs to be done, besides returning the same set of keys
            else
                error("Unrecognized enum value for GLFW button press action: $action")
            end
        end
        events[Mouse.Buttons] = set # trigger setfield event!
    end)
    return
end

"""
Adds the Keyboard.Buttons event via GLFW
"""
function add!(events, ::Type{Keyboard.Buttons})
    @needs events: window = Window
    GLFW.SetKeyCallback(window, (window, button, scancode, action, mods) -> begin
        set = events[Keyboard.Buttons]
        button_enum = Keyboard.Button(button)
        if button != GLFW.KEY_UNKNOWN
            if action == GLFW.PRESS
                push!(set, button_enum)
            elseif action == GLFW.RELEASE
                delete!(set, button_enum)
            elseif action == GLFW.REPEAT
                # nothing needs to be done, besides returning the same set of keys
            else
                error("Unrecognized enum value for GLFW button press action: $action")
            end
        end
        events[Keyboard.Buttons] = set # trigger setfield event!
    end)
    return
end

function add!(events::Composable, ::Type{Mouse.Drag})
    @needs events: Mouse.Buttons, Mouse.Position, Mouse.Drag
    
    local indrag::Bool = false
    local tracked_mousebutton::Mouse.Button = Mouse.left

    on(events, Mouse.Position, Mouse.Buttons) do mp, buttons
        # only track if still the same button is pressed
        if length(buttons) == 1 &&
                (!indrag || tracked_mousebutton == first(buttons))
            if !indrag
                tracked_mousebutton = first(buttons); indrag = true
                events[Mouse.Drag] = Mouse.down # just started, so dragging is still false
                return
            elseif indrag
                events[Mouse.Drag] = Mouse.pressed
                return
            end
        end
        # already on notpressed, no need for update
        if events[Mouse.Drag] != Mouse.notpressed
            events[Mouse.Drag] = indrag ? Mouse.up : Mouse.notpressed
        end
        indrag = false
        return
    end
end


function add!(events::Composable, ::Type{Area})
    @needs events: window = Window
    GLFW.SetFramebufferSizeCallback(window, (window, w, h) -> begin
        rect = events[Area]
        events[Area] = IRect(minimum(rect), w, h)
    end)
    GLFW.SetWindowPosCallback(window, (window, x, y) -> begin
        rect = events[Area]
        events[Area] = IRect(x, y, widths(rect))
    end)
    return
end


button_key{T}(x::Type{T}) = error("Must be a keyboard or mouse button. Found: $T")
button_key(x::Type{Keyboard.Button}) = Keyboard.Buttons
button_key(x::Type{Mouse.Button}) = Mouse.Buttons
button_key{T}(x::Set{T}) = button_key(T)
button_key{T}(x::T) = button_key(T)

"""
returns true if `button` is pressed in events[Mouse.Buttons or Keyboard.Buttons]
"""
function ispressed(events::Composable, button)
    @needs events: buttons = button_key(button)
    if isa(button, Set)
        return buttons == button
    else
        return length(buttons) == 1 && first(buttons) == button
    end
end
