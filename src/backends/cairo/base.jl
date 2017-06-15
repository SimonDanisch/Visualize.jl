import Cairo
using ..Visualize.JLRasterization: JLRasterizer
using Colors

@field CairoContext
@field CairoSurface

abstract type AbstractCairoWindow <: AbstractWindow end

@composed type CairoWindow <: AbstractCairoWindow
    <: Window
    Canvas
end



function default(::Type{Canvas}, window::Partial{CairoWindow})
    CairoCanvas(window.val)
end

@composed type CairoCanvas <: AbstractCanvas
    <: JLCanvas
    CairoSurface
    CairoContext
end

function default(::Type{ColorBuffer}, canvas::Partial{CairoCanvas})
    resolution = get!(canvas, Resolution)
    (zeros(ARGB32, resolution...), )
end

function default(::Type{CairoContext}, window::Partial{CairoCanvas})
    surf = get!(window, CairoSurface)
    println("Ima creatin da context")
    Cairo.CairoContext(surf)
end

function default(::Type{CairoSurface}, window::Partial{CairoCanvas})
    println("Ima make a cairo surface")
    resolution = get!(window, Resolution)
    Cairo.CairoRGBSurface(resolution...)
end


function emit_line_vertex(cr, v, scene, uniforms)
    vert = vert_linesegments(v, scene, uniforms)
    pos = clip2pixel_space(vert.position, scene.resolution)
    Cairo.set_line_width(cr, vert.thickness)
    Cairo.set_source_rgba(cr, vert.color...)
    pos
end

function emit_linesegment(cr, v1, v2, scene, uniforms)
    pos = emit_line_vertex(cr, v1, scene, uniforms)
    Cairo.move_to(cr, pos[1], pos[2])
    pos = emit_line_vertex(cr, v2, scene, uniforms)
    Cairo.line_to(cr, pos[1], pos[2])
end

function Drawable(window::AbstractCairoWindow, primitive::LineSegments)
    cr = window[Canvas][CairoContext]
    verts = primitive[Vertices]
    vbo = reinterpret(NTuple{2, eltype(verts)}, verts)
    uniforms = LineAttributes(primitive)
    args = (window[Scene], uniforms)
    drawable = function draw_line_segments(vbo, scene_unifoms)
        scene, uniforms = scene_unifoms
        for (a, b) in vbo
            emit_linesegment(cr, a, b, scene, uniforms)
            Cairo.stroke(cr)
        end
    end
    drawable, (vbo, args)
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

function draw_window!(window::AbstractCairoWindow)
    canvas = window[Canvas]
    cr = canvas[CairoContext]
    Cairo.save(cr)
    Cairo.set_source_rgba(cr, get(window, Color)...)    # light gray
    Cairo.rectangle(cr, 0.0, 0.0, get(window, Visualize.Resolution)...) # background
    Cairo.fill(cr)
    Cairo.restore(cr)
    Cairo.reset_clip(cr)
    for (prim, (drawable, args)) in window[Visualize.Renderlist]
        Cairo.save(cr)
        drawable(args...)
        Cairo.restore(cr)
    end
    return
end

#
# function (r::JLRasterizer{Vert, Args, FragN}){Vert, Args, FragN}(
#         canvas::AbstractCairoWindow, vertex_array::AbstractArray{Vert}, uniforms::Args
#     )
#     framebuffers = canvas[ColorBuffer]; depthbuffer = canvas[DepthBuffer]
#     resolution = Vec2f0(size(framebuffers[1]))
#     # hoisting out functions... Seems to help inference a bit. Or not?
#     vshader = r.vertexshader
#     gshader = r.geometryshader
#     fshader = r.fragmentshader
#     FragNVal = Val{FragN}()
#     fragments_drawn = 0
#     clip_triangles = NTuple{3, Vec2f0}[]
#     for face in vertex_array
#         vertex_stage = map(reverse(face)) do f
#             vshader(f, uniforms...)
#         end
#         geom_stage = if isa(r.geometryshader, Void)
#             (vertex_stage,)
#         else
#             reset!(r.geometry_view)
#             gshader(r.emit, vertex_stage, uniforms...)
#             r.geometry_view.view
#         end
#         for geom_face in geom_stage
#             fdepth = map(geom_face) do vert
#                 fv = first(vert)
#                 p = clip2pixel_space(fv, resolution)
#                 p[Vec(1, 2)], p[3]
#             end
#             f = map(first, fdepth)
#             push!(clip_triangles, f)
#             depths = map(last, fdepth)
#             vertex_out = map(last, geom_face)
#             # Bounding rectangle
#             mini = max.(reduce(broadcastmin, f), 1f0)
#             maxi = min.(reduce(broadcastmax, f), resolution)
#             area = edge_function(f[1], f[2], f[3])
#             for y = mini[2]:maxi[2]
#                 for x = mini[1]:maxi[1]
#                     p = Vec(x, y)
#                     w = Vec(
#                         edge_function(f[2], f[3], p),
#                         edge_function(f[3], f[1], p),
#                         edge_function(f[1], f[2], p)
#                     )
#                     yi, xi = round(Int, y), round(Int, x)
#                     if all(w-> w <= 0f0, w) && checkbounds(Bool, framebuffers[1], yi, xi)
#                         bary = w / area
#                         depth = bary[1] * depths[1] + bary[2] * depths[2] + bary[3] * depths[3]
#
#                         if depth <= depthbuffer[yi, xi]
#                             depthbuffer[yi, xi] = depth
#                             fragment_in = interpolate(bary, vertex_out, FragNVal)
#                             fragment_out = fshader(fragment_in, uniforms...)
#                             for i = eachindex(fragment_out)
#                                 src_color = framebuffers[i][yi, xi]
#                                 dest_color = fragment_out[i]
#                                 fragments_drawn += 1
#                                 framebuffers[i][yi, xi] = standard_transparency(
#                                     src_color,
#                                     RGBA{Float32}(dest_color[1], dest_color[2], dest_color[3], dest_color[4])
#                                 )
#                             end
#                         end
#                     end
#                 end
#             end
#         end
#     end
#     for face in clip_triangles
#         for point in face
#             cairo_line_to(cr, point[1], point[2])
#         end
#         cairo_close_path(cr);
#     end
#     clip(cr)
#     set_source_surface(cr, image, 0, 0)
#     paint(cr)
#     println("fragments drawn: ", fragments_drawn)
#     return
# end
#
#
# function rasterizer(
#         window::AbstractCairoWindow,
#
#         vertexarray::AbstractArray,
#         uniforms::Tuple,
#         vertexshader,
#         fragmentshader;
#
#         geometryshader = nothing,
#         max_primitives = 4,
#         primitive_in = :points,
#         primitive_out = :triangle_strip,
#     )
#     jl_rasterizer()
# end
