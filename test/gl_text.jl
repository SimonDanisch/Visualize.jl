using Visualize, GeometryTypes, ModernGL
using Visualize: GLRasterization, TextUniforms, get_texture_atlas, Sprite2
using Visualize.GLRasterization: show!, destroy!
using GPUArrays

resolution = (1024, 1024)
window = GLFWWindow(Area => resolution)
GLBackend.init(window[Window])

for event in Visualize.NativeWindowEvents
    add!(window, event)
end
show!(window)
window[Visualize.Open] = true

proj = orthographicprojection(SimpleRectangle(0, 0, resolution...), -10_000f0, 10_000f0)
uniforms = TextUniforms(
    proj,
    Vec4f0(1, 0, 0, 1),
    Vec4f0(1, 0, 1, 1)
)

atlas = get_texture_atlas();

text = Visualize.Text(
    Sprite2[],
    Char[],
    atlas,
    [0],
    Visualize.defaultfont(),
    45f0,
    0f0,
    Vec4f0(0f0, 0f0, 0f0, 1f0),
    Point2f0(0),
    1.5
);

print(text, 'c')
print(text, " nice test bro!")
text.color = Vec4f0(1f0, 0f0, 0f0, 1f0)
print(text, " Muashahahaha@")

uniform_buff = UniformBuffer(uniforms);
vbo = VertexArray(text.data, face_type = Face{1, OffsetInteger{1, GLint}});
Visualize.vertex_main(text.data[1], uniforms, ())
atlas_tex = GPUArrays.buffer(GLRasterization.atlas_texture(atlas));
draw_particles = GLRasterizer(
    vbo, (uniform_buff, atlas_tex),
    Visualize.vertex_main, Visualize.fragment_main;
    geometryshader = Visualize.geometry_main
)

glDisable(GL_DEPTH_TEST)
glClearColor(1, 1, 1, 0)
GLAbstraction.enabletransparency()

@async begin
    while isopen(window)
        GLFW.PollEvents()
        glViewport(0, 0, widths(window[Area])...)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        draw_particles(vbo, (uniform_buff, atlas_tex))
        GLRasterization.swapbuffers!(window)
        sleep(0.001)
        yield()
    end
    destroy!(window)
end
