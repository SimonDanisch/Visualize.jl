using GLAbstraction, GeometryTypes, FieldTraits, Visualize, Colors, ModernGL
using FieldTraits: @composed, cfieldtype, @field
using Visualize: ImageData, Primitive, SpatialOrder, FRect, Ranges

@field MeshResolution

"""
Supplies the resolution of a mesh. This field will be used when converting a
GeometryPrimitive to a mesh
"""
MeshResolution


type VertexArray{T}
    id::GLuint
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
        mins = Vec(minimum.(r))
        maxs = Vec(maximum.(r))
        FRect(mins, maxs .- mins)
    end
    resolution = get(image, MeshResolution, (2, 2))
    VertexArray(uvmesh(prim, resolution), 1)
end

events = Visualize.WindowEvents()
import Visualize: Image
test = Image(ImageData => rand(RGB{Float32}, 512, 512))
test = GLImage(test)


function show(canvas::GLCanvas, glimage::GLImage)
    shader = GLVisualizeShader(
        "test.frag", "test.vert",
    )
end


function execute_program(vertexarray, vertexshader, fragmentshader)

    map(enumerate(vertexarray)) do i, face
        gl = VertexData(i)
        vertex_stage = vertexshader.(gl, face)
        gl.position

    end
end

using GeometryTypes

framebuffer = zeros(500, 500)
face = (Point2f0(1, 1), Point2f0(100, 100), Point2f0(100, 1))
rasterize2(framebuffer, face)

using FileIO
save("test.png", framebuffer)

inhalfspace(30, 30, face)
test = 1
for y = mini[2]:maxi[2], x = mini[1]:maxi[1]
    test += 1
end
test
