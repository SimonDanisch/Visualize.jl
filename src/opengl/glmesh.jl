using GeometryTypes, StaticArrays, ModernGL, Visualize
import GLAbstraction, GLWindow, ColorVectorSpace
import Transpiler: mix, smoothstep, gli
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

function blinnphong{NV, T}(V, N, L::Vec{NV, T}, color, shading, light)
    diff_coeff = max(dot(L, N), T(0f0))
    H = normalize(L + V)
    spec_coeff = max(dot(H, N), T(0.0)) ^ (shading.shininess)
    if diff_coeff <= T(0.0)
        spec_coeff = T(0.0)
    end
    amb = light.ambient .* shading.ambient
    diff = light.diffuse .* light.diffuse_power
    diffc = diff .* color
    diffc2 = diffc * diff_coeff
    spec = light.specular .* light.specular_power
    spec2 = spec .* shading.specular
    spec3 = spec2 * spec_coeff
    a1 = amb .+ diffc2
    return a1 .+ spec3
end

function vertmesh(vertex, light, shading, args)
    #(solid_color, proj, view)
    proj = args[2]
    viewmodel = args[3]
    position = vertex.position; normal = vertex.normal

    position_camspace = viewmodel * Vec4f0(position[1], position[2], position[3],  1f0)
    # direction to light
    lightdir = normalize(light.position .- position)
    # direction to camera
    pos = -position_camspace[Vec(1,2,3)]
    # screen space coordinates of the vertex
    pos_screen = proj * position_camspace
    v2frag = Vert2Frag(pos, normal, lightdir)
    pos_screen, v2frag
end

function fragmesh(vertex_out, light, shading, args)
    # (solid_color, proj, view)
    solid_color = args[1]
    position = vertex_out.position
    L = normalize(vertex_out.normal)
    N = normalize(vertex_out.lightdir)
    light1 = blinnphong(position, N, L, solid_color, shading, light)
    light2 = blinnphong(position, N, -L, solid_color, shading, light)
    c = light1 .+ light2 * 0.4f0
    (Vec4f0(c[1], c[2], c[3], 1f0),)
end

using FileIO
faces = rand(UInt32.(1:99), 300)
faces = reinterpret(GLTriangle, faces)
catmesh = Base.view([Vertex(rand(Vec3f0), rand(Vec3f0)) for i = 1:100], faces)

proj = perspectiveprojection(42f0, 1f0, 0.1f0, 10f0)
view = lookat(Vec3f0(1.5), Vec3f0(0.5), Vec3f0(0, -1, 0))

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

draw_cat = GLRasterizer(
    vbo, uniforms,
    vertmesh, fragmesh;
)

glDisable(GL_DEPTH_TEST)
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
# TODO DONT HARDCODE PRIMITIVE TYPE (LOL)
