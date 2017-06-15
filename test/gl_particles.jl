using Visualize, GeometryTypes, ModernGL
using Visualize: GLRasterization, Uniforms, VertexCS, get_texture_atlas, Sprite2, Window
using Visualize.GLRasterization: show!, destroy!, swapbuffers!
using GPUArrays

resolution = (1024, 1024)
window = GLFWWindow(Area => resolution)
for event in Visualize.NativeWindowEvents
    add!(window, event)
end
show!(window)
window[Visualize.Open] = true
GLBackend.init(window[Window])

proj = orthographicprojection(SimpleRectangle(0, 0, resolution...), -10_000f0, 10_000f0)

proj
uniforms = Visualize.Uniforms(
    proj,
    Vec4f0(1, 0, 0, 1),
    Vec4f0(1, 0, 1, 1),
    Visualize.circle
)

N = 20
middle = Vec2f0(resolution) / 2f0
radius = min(resolution...) / 2f0
vertices = [VertexCS(
    Vec2f0((sin(2pi * (i / N)) , cos(2pi * (i / N))) .* radius) .+ middle,
    Vec4f0(1, i/N, 0, 1),
    Vec2f0(40, 40)
) for i = 1:N]
uniform_buff = UniformBuffer(uniforms);
vbo = VertexArray(vertices, face_type = Face{1, OffsetInteger{1, GLint}});

draw_particles = GLRasterizer(
    vbo, (uniform_buff,),
    Visualize.vertex_main, Visualize.fragment_main;
    geometryshader = Visualize.geometry_main
)

glClearColor(0, 0, 0, 0)
glDisable(GL_DEPTH_TEST)
GLAbstraction.enabletransparency()

@async begin
    while isopen(window)
        GLFW.PollEvents()
        glViewport(0, 0, widths(window[Area])...)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        draw_particles(vbo, (uniform_buff,))
        swapbuffers!(window)
        sleep(0.001)
        yield()
    end
    destroy!(window)
end
