using Visualize, GeometryTypes

using Visualize: add!, PerspectiveCamera, TranslationSpeed, LookAt, EyePosition
using Visualize: Area, RotationSpeed, Translation, Rotation, Keyboard, Window
using Visualize: Mouse, Pan, View, Projection
using Visualize.GLRasterization: GLFWWindow

window = GLFWWindow()
for event in Visualize.NativeWindowEvents
    add!(window, event)
end
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
    Mouse.right, Set([Keyboard.left_control])
)
add!(cam, Rotation, window,
    Mouse.left, Set([Keyboard.left_control])
)
add!(cam, Projection, View)
add!(cam, EyePosition, LookAt)

using ModernGL, FileIO
import Visualize: GLRasterization
using GLRasterization: VertexArray, normalmesh, UniformBuffer, GLRasterizer
using Visualize: VertexN, Light, Shading, vert_mesh, frag_mesh


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

# Create a functor
catmesh = normalmesh(load(Pkg.dir("GLVisualize", "assets", "cat.obj")))
catmesh = Base.view(
    reinterpret(VertexN, catmesh.parent), catmesh.indexes[1]
)
GLFW.ShowWindow(window[Window])

vbo = VertexArray(catmesh)
args = (Vec3f0(1, 0, 0), cam[Projection], cam[View])
uniforms = map(UniformBuffer, (light, shading, args))
draw_cat = GLRasterizer(
    vbo,
    uniforms,
    vert_mesh, frag_mesh
)

@async begin
    while !GLFW.WindowShouldClose(window[Window])
        GLFW.PollEvents()
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        args = (Vec3f0(1, 0, 0), cam[Projection], cam[View])
        uniforms[3][1] = args # update
        draw_cat(vbo, uniforms)
        GLFW.SwapBuffers(window[Window])
        sleep(0.001)
        yield()
    end
end


GLFW.DestroyWindow(window[Window])
