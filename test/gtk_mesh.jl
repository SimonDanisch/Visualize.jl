using Iterators, FileIO, Colors
using Visualize, GeometryTypes, GtkReactive, ModernGL

using Visualize.GLRasterization
using Visualize.GLRasterization: swapbuffers!, destroy!, GtkWindow, GtkParent, OpenGLVersion, GLCanvas, make_context_current
using Visualize: VertexN, Light, Shading, vert_mesh, frag_mesh, Visible, NativeWindow
using Visualize: Resolution, View, ProjectionView, EyePosition, Projection, Name
using Visualize: VertexN, Light, MeshUniforms, Shading, vert_mesh, frag_mesh
using Visualize: Model, Color, ShadingFunction, Debugging, Canvas, add!
using FieldTraits: Partial, default, on

parent = Gtk.Window("Test", 800, 600, true, true)
box = Gtk.Box(:v)
tb = textbox(String)
sl = GtkReactive.slider(linspace(0.0, 20.0, 100))
mesh_color = map(sl) do val
    RGBA{Float32}(val, 0,0,1)
end
push!(box, tb)
push!(box, sl)

push!(parent, box)
window = GLRasterization.GtkWindow(OpenGLVersion => v"3.3.0", GtkParent => box)
Gtk.setproperty!(box, :expand, window[NativeWindow], true)

Gtk.showall(parent)
# for event in Visualize.NativeWindowEvents
#     add!(window, event)
# end
# add!(window, Mouse.Drag)
add!(window, Mouse.Buttons)
add!(window, Mouse.Position)
add!(window, Mouse.Drag)

cam = PerspectiveCamera(
    TranslationSpeed => 1f0,
    LookAt => Vec3f0(0),
    EyePosition => Vec3f0(6, 6, 8),
    Rotation => Vec3f0(0),
    Area => window[Area],
    RotationSpeed => 0.1f0
)

add!(cam, Translation, window,
    Mouse.right, Set(Keyboard.Button[])
)
add!(cam, Rotation, window,
    Mouse.left, Set(Keyboard.Button[])
)
add!(cam, Projection, View)
add!(cam, EyePosition, LookAt)

make_context_current(window[NativeWindow])
on(cam, ProjectionView) do pv
    Gtk.queue_render(window[NativeWindow])
end

catmesh = normalmesh(load(Pkg.dir("GLVisualize", "assets", "cat.obj")))
catmesh = Base.view(
    reinterpret(Visualize.VertexN, catmesh.parent), catmesh.indexes[1]
)
vbo = VertexArray(catmesh);

args = MeshUniforms(
    ShadingFunction => (V, N, L, color, shading, light) -> return L
)

canvas = window[Canvas];
for field in FieldTraits.Fields(eltype(canvas))
    if haskey(cam, field)
        FieldTraits.link!(field, cam => canvas)
    end
end
light = Light(
    Vec3f0(10),
    Vec3f0(0.0),
    Vec3f0(0.9),
    1.0f0,
    Vec3f0(0.2),
    1.0f0
)
shading = Shading(
    Vec3f0(0.0),
    Vec3f0(0.3),
    8.0f0
)
uniforms = (canvas, UniformBuffer(light), UniformBuffer(shading), UniformBuffer(args));

draw_cat = GLRasterizer(
    vbo,
    uniforms,
    vert_mesh, Visualize.frag_mesh
)

function gtk_render(gl_area, gdk_context)
    global draw_cat, uniforms, args, vbo, window
    glEnable(GL_DEPTH_TEST)
    glDepthMask(GL_TRUE)
    glDepthFunc(GL_LEQUAL)
    glDisable(GL_CULL_FACE)
    GLAbstraction.enabletransparency()
    glClearColor(1,1,1,1)
    glViewport(0, 0, widths(window[Area])...)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    draw_cat(vbo, uniforms)
    glFlush()
    return false
end


Gtk.signal_connect(gtk_render, window[NativeWindow], "render")
cam[View] = eye(Mat4f0)
# signal_connect(parent, :destroy) do widget
#     Gtk.gtk_quit()
# end
# Gtk.gtk_main()
