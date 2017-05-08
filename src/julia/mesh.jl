module MeshRender

using GeometryTypes

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

function vertexshader(vertex, light, shading, args)
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

function blinnphong{NV, T}(V::Vec{NV, T}, N, L, color, shading, light)
    lambertian = max(dot(L, N), 0f0)
    half_direction = normalize(L .+ V)
    specular_angle = max(dot(half_direction, N), 0.0)
    specular = specular_angle ^ 16f0
    surf_color = (lambertian * color) .+ (specular * shading.specular)
    return light.ambient .+ surf_color
end

function fragmentshader(vertex_out, light, shading, args)
    # (solid_color, proj, view)
    solid_color = args[1]
    V = vertex_out.position
    L = normalize(vertex_out.lightdir)
    N = normalize(vertex_out.normal)
    c = blinnphong(V, N, L, solid_color, shading, light)
    (Vec4f0(c[1], c[2], c[3], 1f0),)
end

end
