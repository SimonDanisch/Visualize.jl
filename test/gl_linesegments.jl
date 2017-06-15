using GeometryTypes, Visualize, ModernGL

using Visualize.GLRasterization: GLFWWindow, GLCanvas, VertexArray, UniformBuffer, GLRasterizer
using Visualize: show!, swapbuffers!, destroy!, add_restriction!, FRect
using Visualize: LineVertex, LineUniforms, Resolution, Camera, ProjectionView, translationmatrix
using Visualize: vert_linesegments, geom_linesegments, frag_linesegments, timed_action, poll_actions

resolution = (1024, 1024)
window = GLFWWindow(Resolution => resolution, Camera => Visualize.BasicCamera(), Visualize.Debugging => true)
cam = window[Camera]

FieldTraits.on(cam, Projection, View) do p, v
    cam[Visualize.ProjectionView] = p * v
end
canvas_u = UniformBuffer(GLCanvas, 1, GL_DYNAMIC_DRAW);
push!(canvas_u, GLCanvas());



show!(window)
window[Visualize.Open] = true
cam[Area] = FRect(window[Area])

N = 300
uniforms = LineUniforms(
    eye(Mat4f0),
    20f0,
    4f0,
)

scale = 10f0
res = Vec2f0(resolution)
radius = (min(resolution...) / 2f0) - scale

vertices = [LineVertex(
    (rand(Vec2f0) .* (2f0*res)) .- res,
    scale,
    Vec4f0(1, i/N, 0, 0.9),
) for i = 1:N]
vertices[1]

vbo = VertexArray(vertices, face_type = Face{2, OffsetInteger{1, GLint}});

args = (canvas_u, UniformBuffer(uniforms));

draw_particles = GLRasterizer(
    vbo, args,
    vert_linesegments, frag_linesegments;
    geometryshader = geom_linesegments,
    primitive_in = :lines
);
# action = timed_action() do t
#     cam[View] = translationmatrix(Vec3f0(t * 10f0, 0, 0))
# end

glDisable(GL_DEPTH_TEST)
glDisable(GL_CULL_FACE)
glClearColor(0, 0, 0, 0)
GLAbstraction.enabletransparency()

@async begin
    try
        while isopen(window)
            GLFW.PollEvents()
            poll_actions()
            glViewport(0, 0, widths(window[Area])...)
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
            draw_particles(vbo, args)
            swapbuffers!(window)
            sleep(0.01)
            yield()
        end
    catch e
        println(e)
    finally
        destroy!(window)
    end
end

bb = AABB(map(x-> Point2f0(x.position), vertices))

action = add_restriction!(cam, window,
    IRect(minimum(bb) - 100f0, widths(bb) + 100f0),
    Vec(50, 50)
)
