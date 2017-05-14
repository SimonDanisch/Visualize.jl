#=
This implements the basic event callbacks for a GLFW window.
It can be used as a template for any other window type with events you might want to
add to GLVisualize.
Simpley implement the same methods, and just type it with your window type.
=#

@composed type GLFWWindow <: ReactiveComposable
    <: WindowEvents
    Window
end

@field OpenGLVersion = v"3.1.0"

"""
OpenGL context hint for the window creation with GLFW
Expects a Vector{Tuple{GLenum, Integer}}. E.g:
```Julia
    [
        (GLFW.CONTEXT_VERSION_MAJOR, major),
        (GLFW.CONTEXT_VERSION_MINOR, minor)
    ]
```
"""
@field ContextHints

"""
Tries to create sensible context hints!
Taken from lessons learned at:
[GLFW](http://www.glfw.org/docs/latest/window.html)
"""
function default{X}(::Type{ContextHints}, p::Parent{GLFWWindow, X})
    version = get(p.val, OpenGLVersion)
    major, minor = version.major, version.minor
    # this is spaar...Modern OpenGL !!!!
    # core profile is only supported for OpenGL 3.2+ (and a must for OSX, so
    # for the sake of homogenity, we try to default to it for everyone!)
    if (major > 3 || (major == 3 && minor >= 2 ))
        profile = GLFW.OPENGL_CORE_PROFILE
    else
        profile = GLFW.OPENGL_ANY_PROFILE
    end
    [
        (GLFW.CONTEXT_VERSION_MAJOR, major),
        (GLFW.CONTEXT_VERSION_MINOR, minor),
        (GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE),
        (GLFW.OPENGL_PROFILE, profile)
    ]
end


"""
OpenGL Framebuffer hint for the window creation with GLFW.
Expects a Vector{Tuple{GLenum, Integer}}. E.g:
```Julia
    [
        (GLFW.SAMPLES,      0),
        (GLFW.RED_BITS,     8),
        (GLFW.GREEN_BITS,   8),
        (GLFW.BLUE_BITS,    8)
    ]
```
"""
@field FramebufferHints = [
    (GLFW.SAMPLES,      0),
    (GLFW.DEPTH_BITS,   0),

    (GLFW.ALPHA_BITS,   8),
    (GLFW.RED_BITS,     8),
    (GLFW.GREEN_BITS,   8),
    (GLFW.BLUE_BITS,    8),

    (GLFW.STENCIL_BITS, 0),
    (GLFW.AUX_BUFFERS,  0)
]


function default{X}(::Type{Window}, data::Parent{GLFWWindow, X})
    area = get(data, Area)
    # we create a new context, so we need to clear the shader cache.
    # TODO, cache shaders in GLAbstraction per GL context
    GLFW.WindowHint(GLFW.VISIBLE, get(data, Visible))
    GLFW.WindowHint(GLFW.FOCUSED, get(data, Focused))

    for ch in get(data, FramebufferHints)
        GLFW.WindowHint(ch[1], ch[2])
    end
    for wh in get(data, ContextHints)
        GLFW.WindowHint(wh[1], wh[2])
    end
    debugging = get(data, Debugging)
    @static if is_apple()
        if debugging
            warn("OpenGL debug message callback not available on osx")
            debugging = false
        end
    end
    GLFW.WindowHint(GLFW.OPENGL_DEBUG_CONTEXT, Cint(debugging))
    resolution = round.(Int, widths(get(data, Area)))
    name = get(data, Name)
    window = GLFW.CreateWindow(resolution..., String(name))
    GLFW.MakeContextCurrent(window)

    # tell GLAbstraction that we created a new context.
    # This is important for resource tracking
    GLAbstraction.new_context()

    debugging && glDebugMessageCallbackARB(_openglerrorcallback, C_NULL)
    window
end


"""
Adds the Mouse.Position event via GLFW
"""
function add!(window::GLFWWindow, ::Type{Mouse.Position})
    GLFW.SetCursorPosCallback(window[Window], (native_window, x, y) -> begin
        events[Mouse.Position] = (x, y)
    end)
    return
end

"""
Adds the Mouse.Scroll event via GLFW
"""
function add!(window::GLFWWindow, ::Type{Mouse.Scroll})
    GLFW.SetScrollCallback(window[Window], (native_window, xoffset, yoffset) -> begin
        window[Mouse.Scroll] = (xoffset, yoffset)
    end)
    return
end

"""
Adds the Mouse.Buttons event via GLFW
"""
function add!(window::GLFWWindow, ::Type{Mouse.Buttons})
    GLFW.SetMouseButtonCallback(window[Window], (native_window, button, action, mods) -> begin
        set = window[Mouse.Buttons]
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
        window[Mouse.Buttons] = set # trigger setfield event!
    end)
    return
end

function add!(window::GLFWWindow, ::Type{Area})
    GLFW.SetFramebufferSizeCallback(window[Window], (native_window, w, h) -> begin
        rect = window[Area]
        window[Area] = IRect(minimum(rect), w, h)
    end)
    GLFW.SetWindowPosCallback(window[Window], (window, x, y) -> begin
        rect = window[Area]
        window[Area] = IRect(x, y, widths(rect))
    end)
    return
end


"""
Adds the Keyboard.Buttons event via GLFW
"""
function add!(window::GLFWWindow, ::Type{Keyboard.Buttons})
    GLFW.SetKeyCallback(window[Window], (native_window, button, scancode, action, mods) -> begin
        set = window[Keyboard.Buttons]
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
        window[Keyboard.Buttons] = set # trigger setfield event!
    end)
    return
end

"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#ga6b5f973531ea91663ad707ba4f2ac104)
"""
function hasfocus(window, events)
    GLFW.SetWindowFocusCallback(window[Window], (window, focus::Bool) -> begin
        push!(s, focus)
    end)
    s
end

"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga762d898d9b0241d7e3e3b767c6cf318f)
"""
function entered_window(window, events)
    GLFW.SetCursorEnterCallback(window[Window], (window, entered::Bool) -> begin
        push!(s, entered)
    end)
    s
end

"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function unicode_input(window, events)
    GLFW.SetCharCallback(window[Window], (window, c::Char) -> begin
        push!(s, Char[c])
        push!(s, Char[])
    end)
    s
end

"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
function dropped_files(window, events)
    GLFW.SetDropCallback(window[Window], (window, files) -> begin
        push!(s, map(Compat.String, files))
    end)
    s
end

"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#gaade9264e79fae52bdb78e2df11ee8d6a)
"""
function window_open(window, events)
    GLFW.SetWindowCloseCallback(window[Window], window -> begin
        events[WindowOpen] = false
    end)
end


function renderloop(window::GLFWWindow)
    while isopen(window)
        try
            GLFW.PollEvents()
        catch e
            warn(e)
        end
        yield()
    end
    GLFW.DestroyWindow(window)
end
