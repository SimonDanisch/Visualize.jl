using GeometryTypes, StaticArrays, ModernGL
using Transpiler, Visualize
using Visualize: GLRasterization, TextUniforms, get_texture_atlas, Sprite2
using Visualize.GLRasterization: show!, destroy!, swapbuffers!

function vertex_main(vertex)
    return vertex
end

function geometry_main(emit!, vertex_out)
    pos = vertex_out[1]
    quad = Vec4f0(pos[1], pos[2], pos[1] + 0.4f0, pos[2] + 0.4f0)
    v1 = quad[Vec(1, 2)]
    v2 = quad[Vec(1, 4)]
    v3 = quad[Vec(3, 2)]
    v4 = quad[Vec(3, 4)]
    emit!(Vec4f0(v1[1], v1[2], 0f0, 1f0), Vec4f0(1, 0, 0, 1))
    emit!(Vec4f0(v2[1], v2[2], 0f0, 1f0), Vec4f0(1, 0, 0, 1))
    emit!(Vec4f0(v3[1], v3[2], 0f0, 1f0), Vec4f0(1, 0, 0, 1))
    emit!(Vec4f0(v4[1], v4[2], 0f0, 1f0), Vec4f0(1, 0, 0, 1))
    return
end
fragment_main(geom_out) = (geom_out,)

resolution = (1024, 1024)
window = GLFWWindow(Area => resolution, Visualize.Debugging => true)
for event in Visualize.NativeWindowEvents
    add!(window, event)
end
show!(window)
window[Visualize.Open] = true
N = 20

vertices = VertexArray(
    [Point2f0(sin(2pi * (i / N)) , cos(2pi * (i / N))) for i = 1:N],
    face_type = Face{1, OffsetInteger{1, GLint}}
);
draw = GLRasterizer(
    vertices, (),
    vertex_main, fragment_main,
    geometryshader = geometry_main
)


glClearColor(1, 1, 1, 1)

while isopen(window)
    GLFW.PollEvents()
    glViewport(0, 0, widths(window[Area])...)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glUseProgram(draw.program)
    glBindVertexArray(vertices.id)
    GLRasterization.draw_vbo(vertices)
    swapbuffers!(window)
    sleep(0.001)
    yield()
end
destroy!(window)
