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

@composed type SceneUniforms
    Projection::Mat4f0
    View::Mat4f0
    ProjectionView::Mat4f0
    Resolution::Vec2f0
    EyePosition::Vec3f0
end

function blinnphong{NV, T}(V::Vec{NV, T}, N, L, color, shading, light)
    lambertian = max(dot(L, N), 0f0)
    half_direction = normalize(L .+ V)
    specular_angle = max(dot(half_direction, N), 0.0)
    specular = specular_angle ^ shading.shininess
    surf_color = (lambertian * color) .+ (specular * shading.specular)
    return light.ambient .+ surf_color
end

flat_shading(V, N, L, color, shading, light) = color

immutable Vert2Frag
    color::Vec4f0
    position::Vec3f0
    normal::Vec3f0
    uv::Vec2f0
    lightdir::Vec3f0
end

immutable Vertex2Geom
    uvrect::Vec4f0
    color::Vec4f0
    rect::Vec4f0
end

abstract type AbstractVertex end

immutable VertexN <: AbstractVertex
    position::Vec3f0
    normal::Vec3f0
end
immutable VertexNUV <: AbstractVertex
    position::Vec3f0
    normal::Vec3f0
    uv::Vec2f0
end

abstract type AbstractLineVertex <: AbstractVertex end

@composed immutable LineVertex <: AbstractLineVertex
    Position
    Thickness::Float32
    Color::Vec4f0
end

abstract type Particle <: AbstractVertex end

immutable VertexCS{N, T} <: Particle
    position::Vec{N, T}
    color::Vec4f0
    scale::Vec2f0
end
immutable Sprite{N, T} <: Particle
    position::Point{N, T}
    offset::Vec{2, T}
    scale::Vec{2, T}
    uv::Vec{4, T}
    color::Vec{4, T}
end

# since we don't have traits in that sense, we just define the unions ourselves
# when codegen and the transpiler improves, we could just use FixedDicts with haskey
# which compile away.
const VertexWithColor = Union{Sprite, VertexCS, LineVertex}
const VertexWithThickness = Union{LineVertex}

const Sprite2 = Sprite{2, Float32}
const Sprite3 = Sprite{3, Float32}

to_vec4(v::Vec3f0) = Vec4f0(v[1], v[2], v[3], 1f0)
to_vec4(v::Vec2f0) = Vec4f0(v[1], v[2], 0f0, 1f0)

getuvrect(x::AbstractVertex) = Vec4f0(-0.5f0, -0.5f0, 0.5f0, 0.5f0)
getuvrect(x::Sprite) = x.uv

getuv(x::VertexNUV) = x.uv
getuv(x::AbstractVertex) = Vec2f0(0)

getcolor(v::AbstractVertex, uniforms) = uniforms.color
getcolor(v::VertexWithColor, uniforms) = v.color
getstrokecolor(x) = x.strokecolor
getglowcolor(x) = x.glowcolor
getscale(x) = x.scale

getposition(x::Vec4f0) = x
getposition(x::AbstractVertex) = x.position

getnormal(x) = x.normal

getthickness(x::VertexWithThickness, uniforms) = x.thickness
getthickness(x, uniforms) = uniforms.thickness



function aastep{T}(threshold1::T, value)
    afwidth = norm(Vec2f0(dFdx(value), dFdy(value))) * T(1.05);
    smoothstep(threshold1 - afwidth, threshold1 + afwidth, value)
end


function aastep{T}(threshold1::T, threshold2::T, value::T)
    afwidth = norm(Vec2f0(dFdx(value), dFdy(value))) * T(1.05);
    return (
        smoothstep(threshold1 - afwidth, threshold1 + afwidth, value) -
        smoothstep(threshold2 - afwidth, threshold2 + afwidth, value)
    )
end
