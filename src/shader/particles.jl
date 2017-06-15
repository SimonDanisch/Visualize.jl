function aastep{T}(threshold1::T, value)
    smoothstep(threshold1 - T(0.001), threshold1 + T(0.001), value)
end

circle{T}(uv::Vec{2, T}) = T(0.5) - norm(uv)

type Uniforms{F}
    projection::Mat4f0
    strokecolor::Vec4f0
    glowcolor::Vec4f0
    distance_func::F
end

type TextUniforms
    projection::Mat4f0
    strokecolor::Vec4f0
    glowcolor::Vec4f0
end



vert_particles(vertex, uniforms, image) = vert_particles(vertex, uniforms)
function vert_particles(vertex, canvas, uniforms)
    p = getposition(vertex)
    scale = getscale(vertex)
    return Vertex2Geom(
        getuv(vertex),
        getcolor(vertex),
        Vec4f0(p[1], p[2], scale[1], scale[2])
    )
end


"""
Emits a vertex with
"""
function emit_vertex(emit!, vertex, uv, arg, pos, uniforms)
    datapoint = uniforms.projection * Vec4f0(pos[1], pos[2], 0, 1)
    final_position = uniforms.projection * Vec4f0(vertex[1], vertex[2], 0, 0)
    emit!(datapoint .+ final_position, (uv, arg.color))
    return
end

function geom_particles(emit!, vertex_out, uniforms, image)
    geom_particles(emit!, vertex_out, uniforms)
    return
end
function geom_particles(emit!, vertex_out, uniforms)
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


function sdf2color(dist, bg_color, color)
    inside = aastep(0f0, dist)
    mix(bg_color, color, inside)
end
function frag_particles(geom_out, uniforms, image)
    uv = geom_out[1]; color = geom_out[2]
    dist = -image[uv][1]
    bg_color = Vec4f0(0f0, 0f0, 0f0, 0f0)
    (sdf2color(dist, bg_color, color), )
end
function frag_particles(geom_out, uniforms)
    uv = geom_out[1]; color = geom_out[2]
    dist = uniforms.distance_func(uv)
    bg_color = Vec4f0(0f0, 0f0, 0f0, 0f0)
    (sdf2color(dist, bg_color, color), )
end
