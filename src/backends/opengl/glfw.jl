#=
This implements the basic event callbacks for a GLFW window.
It can be used as a template for any other window type with events you might want to
add to GLVisualize.
Simpley implement the same methods, and just type it with your window type.
=#

@field OpenGLVersion = v"3.1.0"

@composed type GLFWWindow <: AbstractWindow
    <: WindowEvents
    OpenGLVersion
    Window
end


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
function default(::Type{ContextHints}, p::Partial{GLFWWindow})
    version = get(p, OpenGLVersion)
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
    (GLFW.DEPTH_BITS,   32),

    (GLFW.ALPHA_BITS,   8),
    (GLFW.RED_BITS,     8),
    (GLFW.GREEN_BITS,   8),
    (GLFW.BLUE_BITS,    8),

    (GLFW.STENCIL_BITS, 0),
    (GLFW.AUX_BUFFERS,  0)
]


"""
Callback which can be used to catch OpenGL errors.
"""
function openglerrorcallback(
        source::GLenum, typ::GLenum,
        id::GLuint, severity::GLenum,
        length::GLsizei, message::Ptr{GLchar},
        userParam::Ptr{Void}
    )
    errormessage = """
         ________________________________________________________________
        |
        | OpenGL Error!
        | source: $(GLENUM(source).name) :: type: $(GLENUM(typ).name)
        |  $(unsafe_string(message, length))
        |________________________________________________________________
    """
    output = typ == GL_DEBUG_TYPE_ERROR ? error : info
    output(errormessage)
    nothing
end

global const _openglerrorcallback = cfunction(
    openglerrorcallback, Void,
    (GLenum, GLenum,GLuint, GLenum, GLsizei, Ptr{GLchar}, Ptr{Void})
)
function default(::Type{Window}, data::Partial{GLFWWindow})
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
    GLAbstraction.new_context(window)

    debugging && glDebugMessageCallbackARB(_openglerrorcallback, C_NULL)
    window
end


"""
Adds the Mouse.Position event via GLFW
"""
function add!(window::GLFWWindow, ::Type{Mouse.Position})
    GLFW.SetCursorPosCallback(window[Window], (native_window, x, y) -> begin
        window[Mouse.Position] = (x, y)
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
    GLFW.SetWindowPosCallback(window[Window], (native_window, x, y) -> begin
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
function add!(window::GLFWWindow, ::Type{Focused})
    GLFW.SetWindowFocusCallback(window[Window], (native_window, focus::Bool) -> begin
        window[Focused] = focus
    end)
end


"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function add!(window::GLFWWindow, ::Type{Keyboard.Unicode})
    GLFW.SetCharCallback(window[Window], (native_window, c::Char) -> begin
        s[Keyboard.Unicode] = c
    end)
end

"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
function add!(window::GLFWWindow, ::Type{DroppedFiles})
    GLFW.SetDropCallback(window[Window], (native_window, files) -> begin
        window[DroppedFiles] = map(String, files)
    end)
end

"""
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#gaade9264e79fae52bdb78e2df11ee8d6a)
"""
function add!(window::GLFWWindow, ::Type{Open})
    GLFW.SetWindowCloseCallback(window[Window], native_window -> begin
        window[Open] = false
    end)
end


Base.isopen(window::GLFWWindow) = window[Open]
show!(window::GLFWWindow) = GLFW.ShowWindow(window[Window])
destroy!(window::GLFWWindow) = GLFW.DestroyWindow(window[Window])
swapbuffers!(window::GLFWWindow) = GLFW.SwapBuffers(window[Window])

function renderloop(window::GLFWWindow)
    while isopen(window)
        try
            GLFW.PollEvents()
        catch e
            warn(e)
        end
        yield()
    end
    destroy!(window)
end

using Visualize: TextureAtlas, get_texture_atlas
using GPUArrays.GLBackend: GLSampler
# Each opengl context needs it's own texture, since they're not valid across context
const texture_cache = Dict{GLAbstraction.GLContext, GLSampler{Float32, 2}}()
function atlas_texture(atlas::TextureAtlas = get_texture_atlas())
    ctx = GLAbstraction.current_context()
    get!(texture_cache, ctx) do
        GLSampler(
            Array(atlas.images);
            minfilter = :linear,
            magfilter = :linear,
            anisotropic = 16f0,
        )
    end
end
