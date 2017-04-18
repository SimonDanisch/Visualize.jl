using GLAbstraction, GeometryTypes, FieldTraits, Visualize, Colors, ModernGL
using FieldTraits: @composed, cfieldtype, @field
using Visualize: ImageData, Primitive, SpatialOrder
@field MeshResolution
"""
Supplies the resolution of a mesh. This field will be used when converting a
GeometryPrimitive to a mesh
"""
MeshResolution

type VertexArray{T}
    id::ModernGL.GLuint
    length::Int
    indices::T
    context::GLAbstraction.GLContext
    function VertexArray{T}(id, bufferlength, indices::T)
        new(id, bufferlength, indices, GLAbstraction.current_context())
    end
end

@composed type GLImage
    Primitive::VertexArray
    ImageData::Texture
    SpatialOrder
end
immutable UVVertex{N, T}
    position::Point{N, T}
    uv::TextureCoordinate{N, T}
end
(::Type{T}){T <: UVVertex, A, B}(x::Tuple{A, B}) = T(x[1], x[2])

function uvmesh(prim::GeometryPrimitive, resolution = (2, 2))
    uv = decompose(UV{Float32}, prim, resolution)
    positions = decompose(Point2f0, prim, resolution)
    faces = decompose(GLTriangle, prim, resolution)
    vertices = map(UVVertex{2, Float32}, zip(positions, uv))
    view(vertices, faces)
end


function VertexArray(buffer::AbstractArray, attrib_location = 1)
    VertexArray(GLBuffer(buffer), -1, attrib_location)
end
function VertexArray{T, AT <: AbstractArray, IT <: AbstractArray}(
        view::SubArray{T, 1, AT, Tuple{IT}, false}, attrib_location = 1
    )
    indexes = view.indexes[1]
    buffer = view.parent
    VertexArray(GLBuffer(buffer), indexbuffer(indexes), attrib_location)
end

function VertexArray{T}(buffer::GLBuffer{T}, indices, attrib_location)
    id = glGenVertexArrays()
    glBindVertexArray(id)
    if isa(indices, GLBuffer)
        GLAbstraction.bind(indices)
    elseif !isa(indices, Integer)
        error("indexbuffer must be int or GLBuffer")
    end
    GLAbstraction.bind(buffer)
    for i = 1:nfields(T)
        FT = fieldtype(T, i); ET = eltype(FT)
        glVertexAttribPointer(
            attrib_location,
            GLAbstraction.cardinality(FT), GLAbstraction.julia2glenum(ET),
            GL_FALSE, sizeof(T), Ptr{Void}(fieldoffset(T, i))
        )
        glEnableVertexAttribArray(attrib_location)
        attrib_location += 1
    end
    glBindVertexArray(0)
    obj = VertexArray{typeof(indices)}(id, length(buffer), indices)
    #finalizer(obj, GLAbstraction.free)
    obj
end


function Base.convert{T <: GLImage}(::Type{T}, ::Type{Primitive}, image::FieldTraits.ComposableLike)
    prim = if haskey(image, Primitive)
        x = image[Primitive]
        isa(x, VertexArray) && return x
        isa(x, GeometryPrimitive) || error("Primitive needs to be of type GeometryPrimitive. Found: $x")
        x
    else
        r = get(image, Ranges)
        mins = minimum.(r)
        maxs = maximum.(r)
        HyperRectangle(mins, maxs .- mins)
    end
    resolution = get(image, MeshResolution, (2, 2))
    VertexArray(uvmesh(prim, resolution), 1)
end

function show(canvas::GLCanvas, glimage::GLImage)
    shader = GLVisualizeShader(
        "fragment_output.frag", "uv_vert.vert", "texture.frag",
        view = Dict("uv_swizzle" => "o_uv.$(spatialorder)")
    )
end
events = Visualize.WindowEvents()
import Visualize: Image
test = Image(ImageData => rand(RGB{Float32}, 512, 512))
test = GLImage(test)
test[ImageData]
