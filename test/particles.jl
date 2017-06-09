using Visualize, GeometryTypes, ModernGL
using Visualize: GLRasterization, Uniforms, VertexCS, get_texture_atlas, Sprite2
using Visualize.GLRasterization: show!, destroy!
using GPUArrays
GLBackend.init()

resolution = (1024, 1024)
window = GLFWWindow(Area => resolution)
for event in Visualize.NativeWindowEvents
    add!(window, event)
end
show!(window)
window[Visualize.Open] = true

proj = orthographicprojection(SimpleRectangle(0, 0, resolution...), -10_000f0, 10_000f0)
uniforms = Uniforms(
    proj,
    Vec4f0(1, 0, 0, 1),
    Vec4f0(1, 0, 1, 1),
    Visualize.circle
)

N = 20
vertices = [VertexCS(
    Vec2f0((sin(2pi * (i / N)) , cos(2pi * (i / N))) .* 500f0) .+ 350f0,
    Vec4f0(1, i/N, 0, 1),
    rand(Vec2f0) * 50f0
) for i = 1:N]

uniform_buff = UniformBuffer(uniforms);
vbo = VertexArray(vertices);

draw_particles = GLRasterizer(
    vbo, (uniform_buff,),
    Visualize.vertex_main, Visualize.fragment_main;
    geometry_main = Visualize.geometry_main
)
using Transpiler, GeometryTypes
eltype(Tuple{GeometryTypes.Vec{2,Float32},GeometryTypes.Vec{4,Float32}})
glClearColor(1, 1, 1, 0)
glDisable(GL_DEPTH_TEST)
GLAbstraction.enabletransparency()

@async begin
    while isopen(window)
        GLFW.PollEvents()
        glViewport(0, 0, widths(window[Area])...)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        draw_particles(vbo, (uniform_buff,))
        GLRasterization.swapbuffers!(window)
        sleep(0.001)
        yield()
    end
    destroy!(window)
end
