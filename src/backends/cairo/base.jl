
function emit_line_vertex(cr, v)
    vert = Visualize.vert_linesegments(v, canvas, uniforms)
    pos = clip2pixel_space(vert.position, canvas.resolution)
    set_line_width(cr, vert.thickness)
    set_source_rgba(cr, vert.color...)
    pos
end

function emit_linesegment(cr, v1, v2)
    pos = emit_line_vertex(cr, v1)
    move_to(cr, pos...)
    pos = emit_line_vertex(cr, v2)
    line_to(cr, pos...)
    stroke(cr)
end

function draw_line_segments(cr, vbo, canvas, uniforms)
    for (a, b) in vbo
        emit_linesegment(cr, a, b)
    end
end

# immutable Sprite{N, T} <: Particle
#     position::Point{N, T}
#     offset::Vec{2, T}
#     scale::Vec{2, T}
#     uv::Vec{4, T}
#     color::Vec{4, T}
# end
function draw_text(cr, text, canvas, uniforms)
    set_font_face(cr, text.font)
    for (c, sprite) in zip(text.data, text.text)
        vert = Visualize.vert_particles(sprite, canvas, uniforms)
        rect = vert.rect
        pos = rect[Vec(1, 2)]
        scale = rect[Vec(3, 4)]
        pos = clip2pixel_space(Vec4f0(pos[1], pos[2], 0, 1), canvas.resolution)
        move_to(cd, pos...)
        set_source_rgba(cr, vert.color...)
        set_font_size(cr, vert.scale[1])
        show_text(cr, string(c))
    end
end
