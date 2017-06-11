using GeometryTypes, Visualize
using Visualize, GeometryTypes, ModernGL

using Visualize.GLRasterization: show!, destroy!, GLRasterizer

using Visualize: LineVertex, STDCanvas, LineUniforms
using Visualize: vert_linesegments, geom_linesegments, frag_linesegments

resolution = (1024, 1024)
window = GLFWWindow(Area => resolution, Visualize.Debugging => true)
for event in Visualize.NativeWindowEvents
    add!(window, event)
end
show!(window)
window[Visualize.Open] = true

proj = orthographicprojection(SimpleRectangle(0, 0, resolution...), -10_000f0, 10_000f0)
N = 32
uniforms = LineUniforms(
    eye(Mat4f0),
    20f0,
    4f0,
)
canvas = STDCanvas(
    proj,
    eye(Mat4f0),
    proj,
    resolution
)
scale = 20f0
middle = Vec2f0(resolution) ./ 2f0
radius = Float32(min(resolution...) ./ 2f0) - scale

vertices = [LineVertex(
    Vec2f0((sin(2pi * (i / N)) , cos(2pi * (i / N)))) * radius .+ middle,
    scale,
    Vec4f0(1, i/N, 0, 1),
) for i = 1:N]

vbo = VertexArray(vertices, face_type = Face{2, OffsetInteger{1, GLint}});

args = map(UniformBuffer, (canvas, uniforms));

draw_particles = GLRasterizer(
    vbo, args,
    vert_linesegments, frag_linesegments;
    geometryshader = geom_linesegments,
    primitive_in = :lines
);

glDisable(GL_DEPTH_TEST)
glDisable(GL_CULL_FACE)
glClearColor(0, 0, 0, 0)
GLAbstraction.enabletransparency()


@async begin
    while isopen(window)
        GLFW.PollEvents()
        glViewport(0, 0, widths(window[Area])...)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        draw_particles(vbo, args)
        GLRasterization.swapbuffers!(window)
        sleep(0.01)
        yield()
    end
    destroy!(window)
end
