using Visualize, ModernGL
using Visualize: orthographicprojection, perspectiveprojection, lookat
using Visualize: normalmesh, JLCanvas, Area, JLRasterizer, Framebuffer
using Visualize: UniformBuffer, VertexArray, WindowEvents, Window

using FileIO, Images, GeometryTypes

include(Visualize.dir("src", "julia","mesh.jl"))

catmesh = normalmesh(load(Pkg.dir("GLVisualize", "assets", "cat.obj")))
catmesh = Base.view(reinterpret(MeshRender.Vertex, catmesh.parent), catmesh.indexes[1])
proj = perspectiveprojection(42f0, 1f0, 0.1f0, 10f0)
view = lookat(Vec3f0(1.5), Vec3f0(0.5), Vec3f0(0, -1, 0))
solid_color = Vec3f0(0.0, 0.7, 1.0)

light = MeshRender.Light(
    Vec3f0(10),
    Vec3f0(0.0),
    Vec3f0(0.9),
    1.0f0,
    Vec3f0(0.2),
    1.0f0
)
shading = MeshRender.Shading(
    Vec3f0(0.0),
    Vec3f0(0.3),
    8.0f0
)
program_args = (light, shading, (solid_color, proj, view))
events = WindowEvents()
window = events[Window]

uniforms = map(program_args) do x
    UniformBuffer(x)
end;
vbo = VertexArray(catmesh)

draw_cat = GLRasterizer(
    vbo, uniforms,
    MeshRender.vertexshader, MeshRender.fragmentshader
)

glEnable(GL_DEPTH_TEST)
glEnable(GL_CULL_FACE)
glClearColor(1, 1, 1, 0)
GLAbstraction.enabletransparency()

while isopen(window)
    GLWindow.poll_glfw()
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    draw_cat(vbo, uniforms)
    GLWindow.swapbuffers(window)
end
GLFW.DestroyWindow(window)
