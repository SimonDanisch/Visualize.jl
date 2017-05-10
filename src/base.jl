"Enables debugging information for a composable"
@field Debugging = false

"Name of something, usually a String or Symbol"
@field Name = gensym(:Visualize)

"Defines if an object is visible or not"
@field Visible = false

"Defines if an object is focused or not"
@field Focused = false

"a native window"
@field Window

@field Rotation = Quaternion(1, 0, 0, 0)
@field Scale = Vec3f0(1)
@field Position = Vec3f0(0)
@field Translation = Vec3f0(0)

abstract type Transformation <: ReactiveComposable end

@composed type Transform <: Transformation
    Scale
    Rotation
    Translation
end

@field XAxis
@field YAxis
@field ZAxis
@field Primitive

"""
The Area something is view in. Can be a Rectangle or a tuple with two elements.
"""
@field Area = IRect(0, 0, 500, 500)

@field Spacetransform = identity


@field Projection = eye(Mat4f0)
@field View = eye(Mat4f0)
@field ProjectionView = eye(Mat4f0)

@field BoundingBox = AABB{Float32}()

@composed type Shared
    Transform
    BoundingBox
end
