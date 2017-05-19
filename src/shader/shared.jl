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

function aastep{T}(threshold1::T, value)
    smoothstep(threshold1 - T(0.001), threshold1 + T(0.001), value)
end

function aastep{T}(threshold1::T, threshold2::T, value::T)
    afwidth = T(0.001)
    return (
        smoothstep(threshold1 - afwidth, threshold1 + afwidth, value) -
        smoothstep(threshold2 - afwidth, threshold2 + afwidth, value)
    )
end
