####################################
# Lighting

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

function blinnphong{NV, T}(V::Vec{NV, T}, N, L, color, shading, light)
    lambertian = max(dot(L, N), 0f0)
    half_direction = normalize(L .+ V)
    specular_angle = max(dot(half_direction, N), 0.0)
    specular = specular_angle ^ shading.shininess
    surf_color = (lambertian * color) .+ (specular * shading.specular)
    return light.ambient .+ surf_color
end


immutable Vert2Frag
    position::Vec3f0
    normal::Vec3f0
    lightdir::Vec3f0
end
immutable Vertex2Geom
    uvrect::Vec4f0
    color::Vec4f0
    rect::Vec4f0
end


abstract type Vertex end
abstract type Particle <: Vertex end

immutable VertexN <: Vertex
    position::Vec3f0
    normal::Vec3f0
end

immutable VertexCS{N, T} <: Particle
    position::Vec{N, T}
    color::Vec4f0
    scale::Vec2f0
end
