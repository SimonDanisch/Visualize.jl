using Visualize
include(Visualize.dir("julia", "mesh.jl"))

catmesh = normalmesh(load(Pkg.dir("GLVisualize", "assets", "cat.obj")))
proj = perspectiveprojection(42f0, 1f0, 0.1f0, 10f0)
view = lookat(Vec3f0(1.5), Vec3f0(0.5), Vec3f0(0, -1, 0))

framebuffer = ones(RGB{Float32}, 1024, 1024)
depthbuffer = ones(Float32, size(framebuffer))
solid_color = Vec3f0(0.0, 0.7, 1.0)

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

resolution = (500, 500)
w = GLWindow.create_glcontext(resolution = resolution)

uniforms = map((light, shading, (solid_color, proj, view))) do x
    UniformBuffer(x)
end;
vbo = VertexArray(catmesh)
eltype(vbo)
draw_cat = GLRasterizer(
    vbo, uniforms,
    vertmesh, fragmesh;
)

glEnable(GL_DEPTH_TEST)
glEnable(GL_CULL_FACE)
glClearColor(1, 1, 1, 0)
GLAbstraction.enabletransparency()

while isopen(w)
    GLWindow.poll_glfw()
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    draw_cat(vbo, uniforms)
    GLWindow.swapbuffers(w)
end
GLFW.DestroyWindow(w)
