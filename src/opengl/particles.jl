type ProgramVars
    strokecolor::Vec4f0
    glowcolor::Vec4f0
end
immutable Vertex{N, T}
    position::Vec{N, T}
    uvrect::SimpleRectangle{T}
    color::Vec4f0
    scale::Vec2f0
end
immutable Vertex2Geom{N, T}
    uvrect::Rectangle{T}
    color::Vec4f0
    strokecolor::Vec4f0
    glowcolor::Vec4f0
    rect::Rectangle{T}
end

function sprite_vertexshader(vertex, program_vars)
    position = getposition(vertex)
    geom_out = Vertex2Geom(
        getuvrect(vertex),
        getcolor(vertex),
        getstrokecolor(args),
        getglowcolor(args),
        getscale(vertex)
    )
    position, geom_out
end


function emit_vertex(emitvertex!, vertex, uv, offsetted_uv, args)
    datapoint = pvm * Vec4f0(position[1], 1)
    final_position = projection * Vec4f0(vertex, 0, 0)
    position = datapoint .+ final_position
    frag_out = (
        uv,
        offsetted_uv,
        args[1].color[1],
        args.stroke_color[1],
        args.glow_color[1]
    )
    emitvertex!(position, frag_out)
end


function geometry_main(program_args, position, face, emit)
    arg = face[1] # get arguments from first face
    # emit quad as triangle strip
    # v3. ____ . v4
    #    |\   |
    #    | \  |
    #    |  \ |
    #    |___\|
    # v1*      * v2
    ow = arg.rect
    offset, width = ow[(1, 2)], ow[(3, 4)]
    uv_o_w = uvrect[1]
    scale_rel = (final_scale / width)
    hfs = stroke / 2f0
    #minx, miny, maxx, maxy
    uvrect = Vec4f0(-scale_rel, scale_rel)
    # use offset as origin quad (x, y, w, h)
    quad = Vec4f0(-hfs + offset, width + offset + stroke)
    scale = Vec2f0(stroke_width, glow_width) ./ width
    emit_vertex(emit, quad[(1, 2)], uvrect[(1, 4)], uv_o_w[(1, 4)], arg)
    emit_vertex(emit, quad[(1, 4)], uvrect[(1, 2)], uv_o_w[(1, 2)], arg)
    emit_vertex(emit, quad[(3, 2)], uvrect[(3, 4)], uv_o_w[(3, 4)], arg)
    emit_vertex(emit, quad[(3, 4)], uvrect[(3, 2)], uv_o_w[(3, 2)], arg)
end



function aastep(threshold1, value)
    afwidth = length(Vec2f0(dFdx(value), dFdy(value))) * ALIASING_CONST;
    return smoothstep(threshold1 - afwidth, threshold1 + afwidth, value)
end
function aastep(threshold1, threshold2, value)
    afwidth = length(Vec2f0(dFdx(value), dFdy(value))) * ALIASING_CONST;
    return (
        smoothstep(threshold1 - afwidth, threshold1 + afwidth, value) -
        smoothstep(threshold2 - afwidth, threshold2 + afwidth, value)
    )
end

function fragment_main(fragment_in, program_args)
    uv, uv_offset, color, stroke_color, glow_color, atlas = fragment_in
    signed_distance = distance_f(uv, atlas)
    half_stroke = -f_scale[1]
    inside_start = max(half_stroke, 0.0)
    inside = aastep(inside_start, signed_distance)
    final_color = fill(inside, args)
    (final_color,)
end
