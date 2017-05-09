using GeometryTypes
using StaticArrays
using ModernGL
import GLAbstraction, GLWindow, ColorVectorSpace
import Transpiler: gli
import Transpiler: mix, smoothstep

function aastep{T}(threshold1::T, value)
    smoothstep(threshold1 - T(0.001), threshold1 + T(0.001), value)
end

circle{T}(uv::Vec{2, T}) = T(0.5) - norm(uv)

type Uniforms{F}
    strokecolor::Vec4f0
    glowcolor::Vec4f0
    distance_func::F
    projection::Mat4f0
end

type TextUniforms
    projection::Mat4f0
    strokecolor::Vec4f0
    glowcolor::Vec4f0
end

abstract Particle

immutable Sprite{N, T} <: Particle
    position::Point{N, T}
    offset::Vec{2, T}
    scale::Vec{2, T}
    uv::Vec{4, T}
    color::Vec{4, T}
end
const GLSprite2 = Sprite{2, Float32}
const GLSprite3 = Sprite{3, Float32}

immutable Vertex{N, T} <: Particle
    position::Vec{N, T}
    color::Vec4f0
    scale::Vec2f0
end

immutable Vertex2Geom
    uvrect::Vec4f0
    color::Vec4f0
    rect::Vec4f0
end

getuvrect(x::Vertex) = Vec4f0(0)
getuvrect(x::Sprite) = x.uvrect

getcolor(x) = x.color
getstrokecolor(x) = x.strokecolor
getglowcolor(x) = x.glowcolor
getscale(x) = x.scale
getposition(x) = x.position

function vertex_main(vertex, uniforms)
    p = getposition(vertex)
    scale = getscale(vertex)
    geom = Vertex2Geom(
        getuvrect(vertex),
        getcolor(vertex),
        Vec4f0(p[1], p[2], scale[1], scale[2])
    )
    geom
end

"""
Emits a vertex with
"""
function emit_vertex(emit!, vertex, uv, offsetted_uv, arg, pos, uniforms)
    datapoint = uniforms.projection * Vec4f0(pos[1], pos[2], 0, 1)
    final_position = uniforms.projection * Vec4f0(vertex[1], vertex[2], 0, 0)
    frag_out = (uv, offsetted_uv, arg.color)
    emit!(datapoint .+ final_position, frag_out)
    return
end

function geometry_main(emit!, geom_in, uniforms)
    # get arguments from first face
    # (there is only one in there anywas, since primitive type is point)
    # (position, vertex_out)
    arg = geom_in[1]
    # emit quad as triangle strip
    # v3. ____ . v4
    #    |\   |
    #    | \  |
    #    |  \ |
    #    |___\|
    # v1*      * v2
    pos_scale = arg.rect
    pos = pos_scale[Vec(1, 2)]
    scale = pos_scale[Vec(3, 4)]
    quad = Vec4f0(0f0, 0f0, scale[1], scale[2])
    uv = arg.uvrect
    uvnormed = Vec4f0(-0.5f0, -0.5f0, 0.5f0, 0.5f0)
    emit_vertex(emit!, quad[Vec(1, 2)], uvnormed[Vec(1, 4)], uv[Vec(1, 4)], arg, pos, uniforms)
    emit_vertex(emit!, quad[Vec(1, 4)], uvnormed[Vec(1, 2)], uv[Vec(1, 2)], arg, pos, uniforms)
    emit_vertex(emit!, quad[Vec(3, 2)], uvnormed[Vec(3, 4)], uv[Vec(3, 4)], arg, pos, uniforms)
    emit_vertex(emit!, quad[Vec(3, 4)], uvnormed[Vec(3, 2)], uv[Vec(3, 2)], arg, pos, uniforms)
    return
end
function fragment_main(fragment_in, uniforms)
    uv = fragment_in[1]; uv_offset = fragment_in[2]; color = fragment_in[3];
    signed_distance = uniforms.distance_func(uv)
    inside = aastep(0f0, signed_distance)
    bg = Vec4f0(0f0, 0f0, 0f0, 0f0)
    (mix(bg, color, inside),)
end


"""
Emits a vertex with
"""
function emit_vertex(emit!, vertex, offsetted_uv, arg, pos, uniforms)
    datapoint = uniforms.projection * Vec4f0(pos[1], pos[2], 0, 1)
    final_position = uniforms.projection * Vec4f0(vertex[1], vertex[2], 0, 0)
    frag_out = (offsetted_uv, arg.color)
    emit!(datapoint .+ final_position, frag_out)
    return
end

function geometry_main(emit!, vertex_out, uniforms, image)
    # get arguments from first face
    # (there is only one in there anywas, since primitive type is point)
    # (position, vertex_out)
    arg = vertex_out[1]
    # emit quad as triangle strip
    # v3. ____ . v4
    #    |\   |
    #    | \  |
    #    |  \ |
    #    |___\|
    # v1*      * v2
    pos_scale = arg.rect
    pos = pos_scale[Vec(1, 2)]
    scale = pos_scale[Vec(3, 4)]
    quad = Vec4f0(0f0, 0f0, scale[1], scale[2])
    uv = arg.uvrect
    emit_vertex(emit!, quad[Vec(1, 2)], uv[Vec(1, 4)], arg, pos, uniforms)
    emit_vertex(emit!, quad[Vec(1, 4)], uv[Vec(1, 2)], arg, pos, uniforms)
    emit_vertex(emit!, quad[Vec(3, 2)], uv[Vec(3, 4)], arg, pos, uniforms)
    emit_vertex(emit!, quad[Vec(3, 4)], uv[Vec(3, 2)], arg, pos, uniforms)
    return
end
function fragment_main(geom_out, uniforms, image)
    uv_offset = geom_out[1]; color = geom_out[2];
    signed_distance = -image[uv_offset][1]
    inside = aastep(0f0, signed_distance)
    bg = Vec4f0(1f0, 1f0, 1f0, 0f0)
    (mix(bg, color, inside),)
end
