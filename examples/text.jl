resolution = (500, 500)
w = GLWindow.create_glcontext(resolution = resolution)

proj = orthographicprojection(SimpleRectangle(0, 0, resolution...), -10_000f0, 10_000f0)
uniforms = Uniforms(
    proj,
    Vec4f0(1, 0, 0, 1),
    Vec4f0(1, 0, 1, 1)
)

atlas = get_texture_atlas(w);

text = Text(
    GLSprite2[],
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
print(text, " lololol")
text.color = Vec4f0(1f0, 0f0, 0f0, 1f0)
print(text, " Muashahahaha@")

uniform_buff = UniformBuffer(uniforms);
vbo = VertexArray(text.data, face_type = Face{1, OffsetInteger{1, GLint}});

draw_particles = GLRasterizer(
    vbo, (uniform_buff, atlas.images),
    vertex_main, fragment_main;
    geometry_main = geometry_main
)
glDisable(GL_DEPTH_TEST)
glClearColor(1, 1, 1, 0)
GLAbstraction.enabletransparency()

while isopen(w)
    GLWindow.poll_glfw()
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    draw_particles(vbo, (uniform_buff, atlas.images))
    GLWindow.swapbuffers(w)
end
GLFW.DestroyWindow(w)

Visualize.gl_face_enum(vbo) == GL_TRIANGLES
