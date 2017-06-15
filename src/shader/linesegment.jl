@composed type LineAttributes
    Model::Mat4f0
    Color::Vec4f0
    Thickness::Float32
end

@composed type LineSegments
    Vertices::AbstractArray{<: AbstractLineVertex}
    <: LineAttributes
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



function screen_space(vertex::Vec4f0, canvas)
    return (vertex[Vec(1, 2)] / vertex[4]) .* canvas.resolution
end

function vert_linesegments(vertex, canvas, uniforms)
    m = canvas.projectionview * uniforms.model
    geomout = Vert2Geom(
        m * to_vec4(getposition(vertex)),
        getcolor(vertex, uniforms),
        getthickness(vertex, uniforms)
    )
    return geomout
end

function emit_line_vertex(emit!, geom_in, canvas, uniforms, position::Vec2f0, uv::Vec2f0, index)
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
    emit_line_vertex(emit!, vertex_out, canvas, uniforms, p0 + thickness_aa0 * n0, Vec2f0(0f0, -uv0), 1)
    emit_line_vertex(emit!, vertex_out, canvas, uniforms, p0 - thickness_aa0 * n0, Vec2f0(0f0, uv0), 1)
    emit_line_vertex(emit!, vertex_out, canvas, uniforms, p1 + thickness_aa1 * n0, Vec2f0(l, -uv1), 2)
    emit_line_vertex(emit!, vertex_out, canvas, uniforms, p1 - thickness_aa1 * n0, Vec2f0(l, uv1), 2)
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


broadcast_conv(x::Vector) = x
broadcast_conv(x::Number) = x
broadcast_conv(x::StaticVector) = StaticArrays.Scalar(x)

function default(::Type{Vertices}, p::Partial{LineSegments})
    positions = get!(p, Position)::Vector{<: StaticVector}
    #(isa(positions, Vector) && eltype(positions) <: SVector) || error("Must be vector of static vectors")
    color = get!(p, Color)::Union{<: StaticVector, Vector{<: StaticVector,}}
    thickness = get!(p, Thickness)::Union{<: AbstractFloat, Vector{<: AbstractFloat,}}
    args = broadcast_conv.((positions, thickness, color))
    # TODO sort args into uniforms (if scalar) or vertex array (if array)
    # A bit tricky, since that means we need to figure out vertex & uniform type in a semi
    # dynamic way
    LineVertex.(args...)
end
