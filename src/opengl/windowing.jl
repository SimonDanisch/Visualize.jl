#=
@composed type WindowEvents
    WindowOpen
    WindowSize
    WindowPosition
    EnteredWindow
    HasFocus

    MouseInside
    MouseButtons
    MousePosition
    Scroll

    KeyboardButtons
    UnicodeInput

    DroppedFiles

    # Complex events
    MouseDrag
    LeftClick
    RightClick
    MiddleClick
    Mouse2Object
end
=#

global const windowcallbacks = WindowEvents(
    window_open,
    window_size,
    window_position,
    entered_window,
    hasfocus,

    mouse_buttons,
    mouse_position,
    scroll,

    keyboard_buttons,
    dropped_files,
    unicode_input,
)



"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#gaade9264e79fae52bdb78e2df11ee8d6a)
"""
function window_open(window, events)
    GLFW.SetWindowCloseCallback(window, window -> begin
        events[WindowOpen] = false
    end)
end

"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#ga311bb32e578aa240b6464af494debffc)
"""
function window_size(window, events)
    GLFW.SetFramebufferSizeCallback(window, (window, w::Cint, h::Cint) -> begin
        events[WindowSize] = (w, h)
    end)
    s
end
"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#ga1c36e52549efd47790eb3f324da71924)
"""
function window_position(window, events)
    GLFW.SetWindowPosCallback(window, (window, x::Cint, y::Cint) -> begin
        events[WindowPosition] = (x, y)
    end)
    s
end
"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function keyboard_buttons(window, events)
    keydict = Dict{Int, Bool}()
    GLFW.SetKeyCallback(window, (window, button::Cint, scancode::Cint, action::Cint, mods::Cint) -> begin
        events[KeyboardButtons] = (Int(button), Int(scancode), Int(action), Int(mods))
    end)
    s
end
"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function mouse_buttons(window, events)
    GLFW.SetMouseButtonCallback(window, (window, button::Cint, action::Cint, mods::Cint) -> begin
        events[MouseButtons], (Int(button), Int(action), Int(mods)))
    end)
    s
end
"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
function dropped_files(window, events)
    GLFW.SetDropCallback(window, (window, files) -> begin
        push!(s, map(Compat.String, files))
    end)
    s
end

"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function unicode_input(window, events)
    GLFW.SetCharCallback(window, (window, c::Char) -> begin
        push!(s, Char[c])
        push!(s, Char[])
    end)
    s
end
"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function mouse_position(window, events)
    GLFW.SetCursorPosCallback(window, (window, x::Cdouble, y::Cdouble) -> begin
        push!(s, Vec{2, Float64}(x, y))
    end)
    s
end
"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
function scroll(window, events)
    GLFW.SetScrollCallback(window, (window, xoffset::Cdouble, yoffset::Cdouble) -> begin
        push!(s, Vec{2, Float64}(xoffset, yoffset))
        push!(s, Vec{2, Float64}(0))
    end)
    s
end
"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#ga6b5f973531ea91663ad707ba4f2ac104)
"""
function hasfocus(window, events)
    GLFW.SetWindowFocusCallback(window, (window, focus::Bool) -> begin
        push!(s, focus)
    end)
    s
end
"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga762d898d9b0241d7e3e3b767c6cf318f)
"""
function entered_window(window, events)
    GLFW.SetCursorEnterCallback(window, (window, entered::Bool) -> begin
        push!(s, entered)
    end)
    s
end
