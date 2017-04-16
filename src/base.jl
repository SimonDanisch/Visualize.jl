
@field Screen

@field Rotation = Quaternion(1, 0, 0, 0)
@field Scale = Vec3f0(1)
@field Position = Vec3f0(0)

@composed type Transform
    Scale
    Rotation
    Position
end

@field XAxis
@field YAxis
@field ZAxis

"""
The Area something is view in. Can be a Rectangle or a tuple with two elements.
"""
@field Area = (500, 500)
@field Spacetransform = identity
@field Projection
@field Primitive

@composed type Camera
    Area
    View
    Projection
end
@field BoundingBox = AABB{Float32}()

@composed type Shared
    Links
    Transform
    BoundingBox
    Camera
end
@composed type Canvas
    <: Shared
    WindowEvents
    Screen
    Area
    Spacetransform
end


@field Ranges
"""
Ranges indicate, on what an otherwise dimensionless visualization should be mapped.
E.g. use Ranges to indicate that an image should be mapped to a certain range.
"""
Ranges

function default(x, ::Type{Ranges})
    data = x[ImageData]
    s = get(x, SpatialOrder) # if SpatialOrder in x, gets that, if not gets default(x, SpatialOrder)
    (0:size(data, s[1]), 0:size(data, s[2]))
end
