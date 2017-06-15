using Iterators
using GeometryTypes, GPUArrays
using Visualize: STDCanvas
using Visualize, GeometryTypes, ModernGL
using Visualize.GLRasterization
using Visualize: Debugging
using Visualize.GLRasterization: swapbuffers!, destroy!, show!
using Visualize: View, Projection, ProjectionView

resolution = (1024, 900)
window = GLFWWindow(Area => (800, 600), Debugging => true)

for event in Visualize.NativeWindowEvents
    add!(window, event)
end
add!(window, Mouse.Drag)
window[Visualize.Open] = true
show!(window)

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

canvas = STDCanvas(
    cam[View],
    cam[Projection],
    cam[ProjectionView],
    Vec2f0(resolution),
    cam[EyePosition],
)

uniforms = Uniforms(
    eye(Mat4f0),
    eye(Mat4f0),
    0f0,
    0f0,
    x-> x > 1.0f0,
    (x, u)-> Vec4f0(x, 1f0, 1f0, 1f0),
    mip
)
GLBackend.init(window[Window])
intensities = GLBackend.GLSampler(rand(Float32, 32, 32, 32));
mesh = GLUVWMesh(AABB(Vec3f0(0), Vec3f0(1)))
vertices = map(x-> UVWVertex(x[1], x[2]), zip(mesh.vertices, mesh.texturecoordinates))

vbo = VertexArray(view(vertices, mesh.faces));
program_args = (UniformBuffer(canvas), UniformBuffer(uniforms), GPUArrays.buffer(intensities));
draw_vol = GLRasterizer(
    vbo,
    program_args,
    vert_volume, frag_volume
)

glEnable(GL_DEPTH_TEST)
glDepthMask(GL_TRUE)
glDepthFunc(GL_LEQUAL)
glEnable(GL_CULL_FACE)
glCullFace(GL_FRONT)
GLAbstraction.enabletransparency()
glClearColor(1,1,1,1)

@async begin
    while isopen(window)
        GLFW.PollEvents()
        glViewport(0, 0, widths(window[Area])...)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        program_args[1][1] = STDCanvas(
            cam[View],
            cam[Projection],
            cam[ProjectionView],
            Vec2f0(resolution),
            cam[EyePosition],
        )
        draw_vol(vbo, program_args)
        swapbuffers!(window)
        sleep(0.001)
        yield()
    end
    destroy!(window)
end
