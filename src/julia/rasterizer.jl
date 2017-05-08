using Colors, ColorVectorSpace, GeometryTypes, Interpolations, FileIO
using StaticArrays, ColorVectorSpace
using Visualize: orthographicprojection, perspectiveprojection, lookat

@inline function edge_function(a, b, c)
    (c[1] - a[1]) * (b[2] - a[2]) - (c[2] - a[2]) * (b[1] - a[1])
end
function src_alpha{T <: Colorant}(c::T)
    a = alpha(c)
    a == 0.0 ? zero(T) : c ./ a
end
one_minus_alpha{T <: Colorant}(c::T) = one(T) .- src_alpha(c)
blend(source, dest, src_func, dest_func) = clamp01(src_func(source) .+ dest_func(dest))
ColorTypes.alpha(x::StaticVector) = x[4]
function standard_transparency{T}(source, dest::T)
    (alpha(source) .* source) .+ ((one(eltype(T)) - alpha(source)) .* dest)
end


immutable Sampler{T, N, Buffer} <: AbstractArray{T, N}
    buffer::Buffer
    size::Vec{N, Float32}
end
function Sampler{T, N}(A::AbstractArray{T, N}, interpolation = Linear(), edge = Flat())
    Ai = extrapolate(interpolate(A, BSpline(interpolation), OnCell()), edge)
    Sampler{T, N, typeof(Ai)}(Ai, Vec{N, Float32}(size(A)) - 1f0)
end
@generated function Base.getindex{T, B, N, IF <: AbstractFloat}(x::Sampler{T, N, B}, idx::TextureCoordinate{N, IF})
    quote
        scaled = idx .* x.size + 1f0
        x.buffer[$(ntuple(i-> :(scaled[$i]), Val{N})...)] # why does splatting not work -.-
    end
end


type FixedGeomView{GeomOut, VT}
    buffer::Vector{GeomOut}
    view::VT
    idx::Int
end

function FixedGeomView(T, max_primitives, primitive_in, primitive_out)
    buffer = Vector{Tuple{Point4f0, T}}(max_primitives)
    # TODO implement primitive_in and out correctly
    # this is for triangle_strip and 4 max_primitives
    if max_primitives != 4 || primitive_out != :triangle_strip
        error("Not implemented for max_primitives == $max_primitives and primitive_out == $primitive_out.")
    end
    geometry_view = view(geometry_stage, Face[(1, 2, 3), (3, 2, 4)])
    FixedGeomView(buffer, geometry_view, 1)
end

function reset!(A::FixedGeomView)
    A.idx = 1
end
function Base.push!(A::FixedGeomView, element)
    if A.idx > length(A.buffer)
        error("Emit called more often than max_primitives. max_primitives: $(length(A.buffer))")
    end
    A.buffer[A.idx] = element
    A.idx += 1
    return
end

immutable JLRasterizer{Vertex, N, Args}
    vertexshader
    fragmentshader

    geometryshader
    geometry_view
    emit
end

function JLRasterizer{N, GF}(
        vertex_array::AbstractArray,
        uniforms::Tuple,
        vertexshader,
        fragmentshader;

        geometry_shader = nothing,
        max_primitives = 4,
        primitive_in = :points,
        primitive_out = :triangle_strip,
    )

    emit, geometry_view = nothing, nothing
    if geometryshader != nothing
        T = geometry_return_type(vertex_array, vertexshader, geometryshader, uniforms)
        geometry_view = FixedGeomView(T, max_primitives, primitive_in, primitive_out)
        emit = (position, fragment_args) -> push!(geometry_view, (position, fragment_args))
    end

    return JLRasterizer(
        vertexshader,
        fragmentshader,
        geometryshader,
        geometry_view,
        emit
    )
end

@composed JLCanvas
    Area
    Depthbuffer
    Framebuffer
end
function (r::JLRasterizer{Vertex, N, Args}){Vertex, N, Args}(

        vertex_array::AbstractArray{Vertex}, uniforms::Args
    )
    resolution = Vec2f0(size(first(framebuffer))) - 1f0
    map(vertex_array) do face
        vertex_stage = map(reverse(face)) do f
            vertex_shader(f, uniforms...)
        end
        geom_stage = if r.geometryshader != nothing
            reset!(r.geometry_view)
            r.geometryshader(r.emit, vertex_stage, uniforms...)
            r.geometry_view.view
        else
            (vertex_stage,)
        end
        for geom_face in geom_stage
            fdepth = map(geom_face) do vert
                fv = first(vert)
                clipspace = fv / fv[4]
                position = clipspace[Vec(1, 2)]
                (((position + 1f0) / 2f0) .* resolution) + 1f0, clipspace[3]
            end
            f = map(first, fdepth)
            depths = map(last, fdepth)
            vertex_out = map(last, geom_face)
            # Bounding rectangle
            mini = max.(reduce(min, f), 1f0)
            maxi = min.(reduce(max, f), Vec2f0(size(framebuffer[1])))
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
                        fragment_out = fragment_shader(fragment_in, uniforms...)
                        for i = eachindex(fragment_out)
                            src_color = framebuffer[i][yi, xi]
                            dest_color = fragment_out[i]
                            framebuffer[i][yi, xi] = blend_func(
                                src_color,
                                RGBA{Float32}(dest_color[1], dest_color[2], dest_color[3], dest_color[4])
                            )
                        end
                    end
                end
            end
        end
        return
    end
end

function geometry_return_type(vertex_array, vertex_shader, geometry_shader, uniforms)
    typ = Any
    emit_t{T}(position, ::T) = (typ = T)
    face1 = first(vertex_array)
    vertex_stage = map(reverse(face1)) do f
        vertex_shader(f, uniforms...)
    end
    geometry_shader(emit_t, vertex_stage, uniforms...) # figure out typ
    typ
end
