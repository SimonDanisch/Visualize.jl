using Visualize: CairoWindow, AbstractCairoWindow, Canvas, Scene, ColorBuffer, DepthBuffer, clip2pixel_space, CairoContext
using Visualize.JLRasterization: JLRasterizer, edge_function, interpolate,standard_transparency, broadcastmin, broadcastmax
using FileIO, GeometryTypes, Colors
using Visualize: normalmesh, Light, Shading, MeshUniforms, Camera

x = CairoWindow()


function (r::JLRasterizer{Vert, Args, FragN}){Vert, Args, FragN}(
        window::AbstractCairoWindow, vertex_array::AbstractArray{Vert}, uniforms::Args
    )
    canvas = window[Canvas]
    framebuffers = canvas[ColorBuffer]; depthbuffer = canvas[DepthBuffer]
    resolution = Vec2f0(size(framebuffers[1]))
    # hoisting out functions... Seems to help inference a bit. Or not?
    vshader = r.vertexshader
    gshader = r.geometryshader
    fshader = r.fragmentshader
    FragNVal = Val{FragN}()
    fragments_drawn = 0
    clip_triangles = NTuple{3, Vec2f0}[]
    for face in vertex_array
        vertex_stage = map(reverse(face)) do f
            vshader(f, uniforms...)
        end
        geom_stage = if isa(r.geometryshader, Void)
            (vertex_stage,)
        else
            reset!(r.geometry_view)
            gshader(r.emit, vertex_stage, uniforms...)
            r.geometry_view.view
        end
        for geom_face in geom_stage
            fdepth = map(geom_face) do vert
                fv = first(vert)
                p = clip2pixel_space(fv, resolution)
                p[Vec(1, 2)], p[3]
            end
            f = map(first, fdepth)

            depths = map(last, fdepth)
            vertex_out = map(last, geom_face)
            # Bounding rectangle
            mini = floor(Int, max.(reduce(broadcastmin, f), 1f0))
            maxi = ceil(Int, min.(reduce(broadcastmax, f), resolution))
            area = edge_function(f[1], f[2], f[3])
            fragment_count = fragments_drawn
            for y = mini[2]:maxi[2]
                for x = mini[1]:maxi[1]
                    p = Vec(Float64(x), Float64(y))
                    w = Vec(
                        edge_function(f[2], f[3], p),
                        edge_function(f[3], f[1], p),
                        edge_function(f[1], f[2], p)
                    )
                    yi, xi = (y), (x)
                    if all(w-> w <= 0f0, w) && checkbounds(Bool, framebuffers[1], yi, xi)
                        bary = w / area
                        depth = bary[1] * depths[1] + bary[2] * depths[2] + bary[3] * depths[3]

                        if depth <= depthbuffer[yi, xi]
                            depthbuffer[yi, xi] = depth
                            fragment_in = interpolate(bary, vertex_out, FragNVal)
                            fragment_out = fshader(fragment_in, uniforms...)
                            for i = eachindex(fragment_out)
                                src_color = framebuffers[i][yi, xi]
                                dest_color = fragment_out[i]
                                fragments_drawn += 1
                                color = standard_transparency(
                                    RGBA{Float32}(src_color),
                                    RGBA{Float32}(dest_color[1], dest_color[2], dest_color[3], dest_color[4])
                                )
                                framebuffers[i][yi, xi] = mapc(x-> clamp(x, 0, 1), color)
                            end
                        end
                    end
                end
            end
            if fragments_drawn != fragment_count # only add triangle if it appeared on screen!
                push!(clip_triangles, f)
            end
        end
    end
    cr = canvas[CairoContext]
    Cairo.save(cr)
    Cairo.set_source_rgba(cr, 0.5, 0, 0, 1.0)
    for face in clip_triangles
        for (i, point) in enumerate(face)
            if i == 1
                Cairo.move_to(cr, point[1], point[2])
            else
                Cairo.line_to(cr, point[1], point[2])
            end
        end
        # Cairo.close_path(cr)
    end
    # Cairo.fill(cr)
    Cairo.clip(cr)
    # Cairo.reset_clip(cr)
    Cairo.set_source_surface(cr, Cairo.CairoImageSurface(rotl90(framebuffers[1])), 0, 0)
    Cairo.paint(cr)
    Cairo.restore(cr)
    println("fragments drawn: ", fragments_drawn)
    return
end



catmesh = normalmesh(load(Pkg.dir("GLVisualize", "assets", "cat.obj")))
catmesh = Base.view(
    reinterpret(Visualize.VertexN, catmesh.parent), catmesh.indexes[1]
)

args = MeshUniforms()

light = Light(
    Vec3f0(10),
    Vec3f0(0.0),
    Vec3f0(0.9),
    1.0f0,
    Vec3f0(0.2),
    1.0f0
)
shading = Shading(
    Vec3f0(0.0),
    Vec3f0(0.3),
    8.0f0
)
scene = Visualize.SceneUniforms(x[Camera])

uniforms = (scene, light, shading, args)
raster = JLRasterizer(
    catmesh,
    uniforms,
    Visualize.vert_mesh, Visualize.frag_mesh
)

sf = canvas[Visualize.CairoSurface]
canvas[Visualize.CairoContext] = Cairo.CairoContext(sf)
canvas[DepthBuffer] = zeros(Float32, 500, 500)

Cairo.save(cr);
Cairo.set_source_rgb(cr,1.0,1.0,1.0);    # light gray
Cairo.rectangle(cr,0.0,0.0, get(x, Visualize.Resolution)...); # background
Cairo.fill(cr);
Cairo.restore(cr);
Cairo.save(cr);
Cairo.reset_clip(cr)
raster(x, catmesh, uniforms)
Cairo.write_to_png(canvas[Visualize.CairoSurface], "test.png")
# save("test.png", canvas[Visualize.ColorBuffer][1])

#
# c = CairoPDFSurface("test.pdf", resolution...);
# cr = CairoContext(c);
# Cairo.save(cr);
# set_source_rgb(cr, 1.0, 1.0, 1.0);    # light gray
# rectangle(cr, 0.0, 0.0, resolution...); # background
# fill(cr);
# restore(cr);
