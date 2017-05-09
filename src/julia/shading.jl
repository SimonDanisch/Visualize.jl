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
    specular = specular_angle ^ 16f0
    surf_color = (lambertian * color) .+ (specular * shading.specular)
    return light.ambient .+ surf_color
end
