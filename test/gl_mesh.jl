using Visualize, GeometryTypes, ModernGL
using Visualize.GLRasterization
using Visualize: Debugging
using Visualize.GLRasterization: swapbuffers!, destroy!
using ModernGL, FileIO
using Visualize: GLRasterization, Resolution, View, ProjectionView, EyePosition, Projection
using Visualize: VertexN, Light, MeshUniforms, Shading, vert_mesh, frag_mesh, GLCanvas
using Visualize: Model, Color, ShadingFunction
using Colors

window = GLFWWindow(Area => (800, 600), Debugging => true)
GLCanvas(cam)

for event in Visualize.NativeWindowEvents
    add!(window, event)
end
add!(window, Mouse.Drag)
window[Visualize.Open] = true

cam = PerspectiveCamera(
    TranslationSpeed => 1f0,
    LookAt => Vec3f0(0),
    EyePosition => Vec3f0(6, 6, 8),
    Rotation => Vec3f0(0),
    Area => window[Area],
    RotationSpeed => 0.1f0
)





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
    reinterpret(Visualize.VertexN, catmesh.parent), catmesh.indexes[1]
)
show!(window)

vbo = VertexArray(catmesh);

args = MeshUniforms(
    ShadingFunction => (V, N, L, color, shading, light) -> return L
)

uniforms = (canvas, map(UniformBuffer, (light, shading, args))...)

draw_cat = GLRasterizer(
    vbo,
    uniforms,
    vert_mesh, Visualize.frag_mesh
)

glEnable(GL_DEPTH_TEST)
glDepthMask(GL_TRUE)
glDepthFunc(GL_LEQUAL)
glDisable(GL_CULL_FACE)
GLAbstraction.enabletransparency()
glClearColor(1, 1, 1, 1)


@async begin
    while isopen(window)
        GLFW.PollEvents()
        glViewport(0, 0, widths(window[Area])...)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        canvas = GLCanvas(
            (
                (elem => cam[elem] for elem in (Projection, View, ProjectionView, EyePosition))...,
                Resolution => (800, 600),
            )
        )
        uniforms[1][1] = canvas # update
        draw_cat(vbo, uniforms)
        swapbuffers!(window)
        sleep(0.001)
        yield()
    end
    destroy!(window)
end
