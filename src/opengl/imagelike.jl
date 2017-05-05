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

"""
Supplies the resolution of a mesh. This field will be used when converting a
GeometryPrimitive to a mesh
"""
MeshResolution
@composed type GLImage
    Primitive::VertexArray
    ImageData::Texture
    SpatialOrder
end
