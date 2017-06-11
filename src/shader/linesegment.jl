immutable LineVertex{N}
    position::Vec{N, Float32}
    thickness::Float32
    color::Vec4f0
end

immutable LineUniforms
    model::Mat4f0
    thickness::Float32
    pattern_length::Float32
end

immutable Vert2Geom
    position::Vec4f0
    color::Vec4f0
    thickness::Float32
end

immutable Geom2Fragment
    thickness::Float32
    color::Vec4f0
    uv::Vec2f0
end

to_vec4(v::Vec3f0) = return Vec4f0(v[1], v[2], v[3], 1f0)
to_vec4(v::Vec2f0) = return Vec4f0(v[1], v[2], 0f0, 1f0)

get_position(x::Vec4f0) = x
get_position(x::LineVertex) = x.position

get_color(x::LineVertex, uniforms) = x.color
get_color(x, uniforms) = uniforms.color

get_thickness(x::LineVertex, uniforms) = x.thickness
get_thickness(x, uniforms) = uniforms.thickness

function screen_space(vertex::Vec4f0, canvas)
    return (vertex[Vec(1, 2)] / vertex[4]) .* canvas.resolution
end

function vert_linesegments(vertex, canvas, uniforms)
    # m =  * uniforms.model
    geomout = Vert2Geom(
        canvas.projection * to_vec4(get_position(vertex)),
        get_color(vertex, uniforms),
        get_thickness(vertex, uniforms)
    )
    return geomout
end

function emit_vertex2(emit!, geom_in, canvas, uniforms, position::Vec2f0, uv::Vec2f0, index)
    inpos = geom_in[index].position
    x = (position ./ canvas.resolution) * inpos[4]
    outpos = Vec4f0(x[1], x[2], inpos[3], inpos[4])
    fragout = Geom2Fragment(
        geom_in[index].thickness + 2f0,
        geom_in[index].color,
        uv,
    )
    emit!(outpos, fragout)
    return
end


function geom_linesegments(emit!, vertex_out, canvas, uniforms)
    # get the four vertices passed to the shader:
    p0 = screen_space(vertex_out[1].position, canvas) # start of previous segment
    p1 = screen_space(vertex_out[2].position, canvas) # end of previous segment, start of current segment

    thickness0 = vertex_out[1].thickness
    thickness1 = vertex_out[2].thickness
    thickness_aa0 = thickness0 + 2f0
    thickness_aa1 = thickness1 + 2f0

    # determine the direction of each of the 3 segments (previous, current, next)
    vun0 = p1 - p0
    v0 = normalize(vun0)
    # determine the normal of each of the 3 segments (previous, current, next)
    n0 = Vec2f0(-v0[2], v0[1])
    l = norm(p1 - p0)

    uv0 = thickness_aa0 / thickness0
    uv1 = thickness_aa1 / thickness_aa1
    emit_vertex2(emit!, vertex_out, canvas, uniforms, p0 + thickness_aa0 * n0, Vec2f0(0f0, -uv0), 1)
    emit_vertex2(emit!, vertex_out, canvas, uniforms, p0 - thickness_aa0 * n0, Vec2f0(0f0, uv0), 1)
    emit_vertex2(emit!, vertex_out, canvas, uniforms, p1 + thickness_aa1 * n0, Vec2f0(l, -uv1), 2)
    emit_vertex2(emit!, vertex_out, canvas, uniforms, p1 - thickness_aa1 * n0, Vec2f0(l, uv1), 2)
    return
end


function frag_linesegments(geom_out, canvas, uniforms)
    uv = geom_out.uv; color = geom_out.color
    xy = Vec2f0(0.5f0, uv[2])
    alpha = aastep(0f0, xy[1])
    alpha2 = aastep(-1f0, 1f0, xy[2])
    outcolor = Vec4f0(color[1], color[2], color[3], color[4] * alpha * alpha2)
    (outcolor, )
end

@field DistanceFunction = circle
@field Thickness = 3f0

@composedtype GLLineSegments

    DistanceFunction
    Thickness
    Color
end
