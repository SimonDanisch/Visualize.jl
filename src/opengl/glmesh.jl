using GeometryTypes, StaticArrays, ModernGL, Visualize
import GLAbstraction, GLWindow, ColorVectorSpace
import Transpiler: mix, smoothstep, gli, pow
using Visualize: orthographicprojection, perspectiveprojection, lookat, normalmesh

immutable Light{T}
    position::Vec{3, T}
    ambient::Vec{3, T}
    diffuse::Vec{3, T}
    diffuse_power::T
    specular::Vec{3, T}
    specular_power::T
end

immutable Shading{T}
    ambient::Vec{3, T}
    specular::Vec{3, T}
    shininess::T
end

immutable Vert2Frag
    position::Vec3f0
    normal::Vec3f0
    lightdir::Vec3f0
end

immutable Vertex
    position::Vec3f0
    normal::Vec3f0
end

function vertmesh(vertex, light, shading, args)
    #args = (solid_color, proj, view)
    proj = args[2]
    viewmodel = args[3]
    pos = vertex.position
    position_camspace = viewmodel * Vec4f0(pos[1], pos[2], pos[3],  1f0)
    # direction to light
    lightdir = normalize(light.position .- pos)
    # direction to camera
    # screen space coordinates of the vertex
    pos_screen = proj * position_camspace
    v2frag = Vert2Frag(-position_camspace[Vec(1,2,3)], vertex.normal, lightdir)
    pos_screen, v2frag
end

function blinnphong{NV, T}(V, N, L::Vec{NV, T}, color, shading, light)
    lambertian = max(dot(L, N), 0f0)
    half_direction = normalize(L .+ V)
    specular_angle = max(dot(half_direction, N), 0f0)
    specular = specular_angle ^ 16f0
    surf_color = (lambertian * color) .+ (specular * shading.specular)
    return light.ambient .+ surf_color
end

function fragmesh(vertex_out, light, shading, args)
    # (solid_color, proj, view)
    solid_color = args[1]
    V = vertex_out.position
    L = normalize(vertex_out.lightdir)
    N = normalize(vertex_out.normal)
    c = blinnphong(V, N, L, solid_color, shading, light)
    (Vec4f0(c[1], c[2], c[3], 1f0),)
end
#blinnphong(Vec3f0(0), Vec3f0(0), Vec3f0(0), Vec3f0(0), shading, light)
using FileIO
catmesh = normalmesh(load(Pkg.dir("GLVisualize", "assets", "cat.obj")))
verts = reinterpret(Vertex, catmesh.parent)
catmesh = Base.view(verts, catmesh.indexes[1])
proj = perspectiveprojection(42f0, 1f0, 0.1f0, 10f0)
view = lookat(Vec3f0(2.0), Vec3f0(0.5), Vec3f0(0, 1, 0))

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


# TODO include return expr dependencies
# TODO broadcast disassembling
# TODO tuple turn into arrays, which are not compilable
