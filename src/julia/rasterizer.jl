using Colors, ColorVectorSpace, GeometryTypes, Interpolations, FileIO
using Visualize: orthographicprojection, perspectiveprojection, lookat

@inline function edge_function(a, b, c)
    (c[1] - a[1]) * (b[2] - a[2]) - (c[2] - a[2]) * (b[1] - a[1])
end

function rasterize!{N}(
        depthbuffer,
        framebuffer::NTuple{N, AbstractMatrix},
        vertex_array::AbstractArray,
        vertex_shader,
        vertex_args,
        fragment_shader,
        fragment_args,
    )
    resolution = Vec2f0(size(first(framebuffer))) - 1f0

    map(vertex_array) do face
        # Bounding rectangle
        vertex_stage = map(reverse(face)) do f
            vertex_shader(f, vertex_args)
        end
        fdepth = map(vertex_stage) do vert
            fv = first(vert)
            clipspace = fv / fv[4]
            position = clipspace[Vec(1, 2)]
            (((position + 1f0) / 2f0) .* resolution) + 1f0, clipspace[3]
        end
        f = map(first, fdepth)
        depths = map(last, fdepth)
        vertex_out = map(last, vertex_stage)
        mini = reduce(min, f)
        maxi = reduce(max, f)
        area = edge_function(f[1], f[2], f[3])
        for y = mini[2]:maxi[2], x = mini[1]:maxi[1]
            p = Vec(x, y)
            w = Vec(
                edge_function(f[2], f[3], p),
                edge_function(f[3], f[1], p),
                edge_function(f[1], f[2], p)
            )
            yi, xi = round(Int, y), round(Int, x)
            if all(w-> w >= 0f0, w) && checkbounds(Bool, framebuffer[1], yi, xi)
                bary = w ./ area
                depth = bary[1] * depths[1] + bary[2] * depths[2] + bary[3] * depths[3]

                if depth <= depthbuffer[yi, xi]
                    depthbuffer[yi, xi] = depth
                    fragment_in = ntuple(Val{length(vertex_out[1])}) do vi
                        bary[1] * vertex_out[1][vi] +
                        bary[2] * vertex_out[2][vi] +
                        bary[3] * vertex_out[3][vi]
                    end
                    fragment_out = fragment_shader(fragment_in, fragment_args)
                    for i = eachindex(fragment_out)
                        framebuffer[i][yi, xi] = fragment_out[i]
                    end
                end
            end
        end
        return
    end
    return framebuffer
end
