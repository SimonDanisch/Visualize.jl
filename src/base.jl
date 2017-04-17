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

@field Primitive


@field Area = IRect(0, 0, 500, 500)
@field Spacetransform = identity
"""
The Area something is view in. Can be a Rectangle or a tuple with two elements.
"""
Area

@field Projection = eye(Mat4f0)
@field View = eye(Mat4f0)

@field BoundingBox = AABB{Float32}()

@composed type Shared
    Transform
    BoundingBox
end
