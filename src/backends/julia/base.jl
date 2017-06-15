module JLRasterization

using Colors, ColorVectorSpace, StaticArrays
using GeometryTypes, Interpolations
using ..Visualize: DepthBuffer, ColorBuffer, Area, Scene, AbstractWindow, Window, Canvas, JLCanvas, AbstractCanvas
import ..Visualize: rasterizer

using FieldTraits
using FieldTraits: ComposableLike, @composed, Partial
import FieldTraits: convertfor, default
import Interpolations: interpolate




@composed type JLWindow <: AbstractWindow
    <: Window
    Canvas
end

default(::Type{Canvas}, window::Partial{JLWindow}) = JLCanvas(window.val)




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


type FixedGeomView{GeomOut, VT}
    buffer::Vector{GeomOut}
    view::VT
    idx::Int
end

function FixedGeomView(T, max_primitives, primitive_in, primitive_out)
    buffer = Vector{Tuple{Point4f0, T}}(max_primitives)
    # TODO implement primitive_in and out correctly
    # this is for triangle_strip and 4 max_primitives
    if max_primitives != 4 || primitive_out == :triangle_strip
        error("Not implemented for max_primitives == $max_primitives and primitive_out == $primitive_out.")
    end
    geometry_view = if primitive_in == :triangle_strip
        view(buffer, [Face(1, 2, 3), Face(3, 2, 4)])
    else
        error("$primitive_in not supported. Only :triangle_strip supported right now")
    end
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

immutable JLRasterizer{Vertex, Args, FragN, VS, FS, GS, GV, EF}
    vertexshader::VS
    fragmentshader::FS

    geometryshader::GS
    geometry_view::GV
    emit::EF
end
function (::Type{JLRasterizer{Vertex, Args, FragN}}){Vertex, Args, FragN, VS, FS, GS, GV, EF}(
        vertexshader::VS,
        fragmentshader::FS,
        geometryshader::GS,
        geometry_view::GV,
        emit::EF
    )
    JLRasterizer{Vertex, Args, FragN, VS, FS, GS, GV, EF}(
        vertexshader,
        fragmentshader,
        geometryshader,
        geometry_view,
        emit
    )
end

function geometry_return_type(vertex_array, vertexshader, geometryshader, uniforms)
    typ = Any
    emit_t{T}(position, ::T) = (typ = T)
    face1 = first(vertex_array)
    vertex_stage = map(reverse(face1)) do f
        vertexshader(f, uniforms...)
    end
    geometryshader(emit_t, vertex_stage, uniforms...) # figure out typ
    typ
end

arglength{T <: Tuple}(::Type{T}) = length(T.parameters)
arglength{T <: AbstractArray}(::Type{T}) = 1
arglength{T}(::Type{T}) = nfields(T)


function rasterizer(
        window::AbstractWindow,
        vertexarray::AbstractArray,
        uniforms::Tuple,
        vertexshader::Function,
        fragmentshader::Function;
        geometryshader = nothing,
        max_primitives = 4,
        primitive_in = :points,
        primitive_out = :triangle_strip,
    )

    emit, geometry_view = nothing, nothing
    fragment_in_ndim = if geometryshader != nothing
        T = geometry_return_type(vertexarray, vertexshader, geometryshader, uniforms)
        geometry_view = FixedGeomView(T, max_primitives, primitive_in, primitive_out)
        emit = (position, fragment_args) -> push!(geometry_view, (position, fragment_args))
        arglength(T)
    else
        # when we don't have a geometry shader, vertex shader will feed fragment shader
        T = Base.Core.Inference.return_type(vertexshader, Tuple{eltype(vertexarray), map(typeof, uniforms)...})
        if T <: Tuple
            # TODO error handling
            arglength(T.parameters[2])
        else # if not a tuple, vertex shader doesn't pass any arguments to fragment shader
            0
        end
    end

    raster = JLRasterizer{eltype(vertexarray), typeof(uniforms), fragment_in_ndim}(
        vertexshader,
        fragmentshader,
        geometryshader,
        geometry_view,
        emit
    )
    raster, (vertexarray, uniforms)
end


Base.@pure Next{N}(::Val{N}) = Val{N - 1}()
@inline function interpolate{N, T}(bary, face::NTuple{N, T}, vn::Val{0}, aggregate)
    if T <: Tuple
        aggregate
    else
        T(aggregate...)
    end
end
@inline function interpolate{N}(bary, face, vn::Val{N}, aggregate = ())
    @inbounds begin
        res = (
            bary[1] * getfield(face[1], N) .+
            bary[2] * getfield(face[2], N) .+
            bary[3] * getfield(face[3], N)
        )
    end
    interpolate(bary, face, Next(vn), (res, aggregate...))
end

broadcastmin(a, b) = min.(a, b)
broadcastmax(a, b) = max.(a, b)


function clip2pixel_space(position, resolution)
    clipspace = position / position[4]
    p = clipspace[Vec(1, 2)]
    (((p + 1f0) / 2f0) .* (resolution - 1f0)) + 1f0
end


function (r::JLRasterizer{Vert, Args, FragN}){Vert, Args, FragN}(
        canvas, vertex_array::AbstractArray{Vert}, uniforms::Args
    )
    framebuffers = canvas[ColorBuffer]; depthbuffer = canvas[DepthBuffer]
    resolution = Vec2f0(size(framebuffers[1]))
    # hoisting out functions... Seems to help inference a bit. Or not?
    vshader = r.vertexshader
    gshader = r.geometryshader
    fshader = r.fragmentshader
    FragNVal = Val{FragN}()
    fragments_drawn = 0
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
            mini = max.(reduce(broadcastmin, f), 1f0)
            maxi = min.(reduce(broadcastmax, f), resolution)
            area = edge_function(f[1], f[2], f[3])
            for y = mini[2]:maxi[2]
                for x = mini[1]:maxi[1]
                    p = Vec(x, y)
                    w = Vec(
                        edge_function(f[2], f[3], p),
                        edge_function(f[3], f[1], p),
                        edge_function(f[1], f[2], p)
                    )
                    yi, xi = round(Int, y), round(Int, x)
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
                                framebuffers[i][yi, xi] = standard_transparency(
                                    src_color,
                                    RGBA{Float32}(dest_color[1], dest_color[2], dest_color[3], dest_color[4])
                                )
                            end
                        end
                    end
                end
            end
        end
    end
    println("fragments drawn: ", fragments_drawn)
    return
end

end
