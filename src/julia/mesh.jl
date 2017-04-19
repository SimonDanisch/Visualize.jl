include("rasterizer.jl")

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

function blinnphong{NV, T}(V, N, L::Vec{NV, T}, color, shading, light)
    diff_coeff = max(dot(L, N), T(0f0))
    H = normalize(L + V)
    spec_coeff = max(dot(H, N), T(0.0)) ^ (shading.shininess)
    if diff_coeff <= T(0.0)
        spec_coeff = T(0.0)
    end
    return Vec3f0(
        light.ambient .* shading.ambient .+
        light.diffuse .* light.diffuse_power .* color * diff_coeff .+
        light.specular .* light.specular_power .* shading.specular * spec_coeff
    )
end

function vertmesh(vertex, args)
    proj, viewmodel, light = args
    position, normal = vertex

    position_camspace = viewmodel * Vec4f0(position[1], position[2], position[3],  1f0)
    # direction to light
    lightdir = normalize(light.position - position)
    # direction to camera
    vertex = -position_camspace[Vec(1,2,3)]
    # screen space coordinates of the vertex
    pos_screen = proj * position_camspace
    pos_screen, (vertex, normal, lightdir)
end

function fragmesh(fragment_in, args)
    position, normal, lightdir = fragment_in
    solid_color, shading, light = args
    L = normalize(lightdir)
    N = normalize(normal)
    light1 = blinnphong(position, N, L, solid_color, shading, light)
    light2 = blinnphong(position, N, -L, solid_color, shading, light)
    c = light1 .+ light2 * 0.4f0
    (RGB(c[1], c[2], c[3]),)
end

function normalmesh(prim)
    positions = decompose(Point3f0, prim)
    normals = decompose(Normal{3, Float32}, prim)
    faces = reverse(decompose(GLTriangle, prim))
    vertices = map(identity, zip(positions, normals))
    Base.view(vertices, faces)
end

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
rasterize!(
    depthbuffer,
    (framebuffer,),
    catmesh,
    vertmesh, (proj, view, light),
    fragmesh, (solid_color, shading, light)
);

using FileIO, Images
save("test.png", clamp01.(framebuffer))
