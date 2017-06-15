"""
converts a primitive into a drawable for `window`
"""
function Drawable(window::WT, primitive::PT) where {WT, PT}
    error("Can't draw $PT with window type: $WT")
end

"""
Creates a rasterizer clojure for a certain window type
"""
function rasterizer{WT}(
        window::WT,
        vertexarray::AbstractArray,
        uniforms::Tuple,
        vertexshader::Function,
        fragmentshader::Function;
        geometryshader = nothing,
        max_primitives = 4,
        primitive_in = :points,
        primitive_out = :triangle_strip,
    )
    error("No rasterizer available for window type: $WT")
end

"Enables debugging information for a composable"
@field Debugging = false

"Name of something, usually a String or Symbol"
@field Name = gensym(:Visualize)

"Defines if an object is visible or not"
@field Visible = true

"Defines if an object is focused or not"
@field Focused = false

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
The Area of a viewable. Can be a Rectangle or a tuple with two elements.
"""
@field Area = IRect(0, 0, 500, 500)

"""
Resolution is the smaller brother of Area. It can be NTuple{2, <: Number} or a Vec{2, <: Number}.
"""
@field Resolution

function default(::Type{Resolution}, x::Partial)
    area = get(x, Area) # APIDOC this gets the area if in `x`, or creates a default area
    widths(area)
end


function default(::Type{Area}, x::Partial)
    haskey(x, Resolution) && return convertfor(Area, x, get(x, Resolution))
    default(Area)
end
function convertfor(::Type{Area}, x::Partial, value)
    isa(value, Tuple) && length(value) == 2 && return IRect(0, 0, value...)
    isa(value, SimpleRectangle) && return IRect(origin(value), widths(value))
    throw(UsageError(Area, value))
end


@field Spacetransform = identity


@field Projection = eye(Mat4f0)
@field View = eye(Mat4f0)
@field ProjectionView = eye(Mat4f0)

@field BoundingBox = AABB{Float32}()

@composed type Shared
    Transform
    BoundingBox
end

@field Color = Vec4f0(1f0, 1f0, 1f0, 1f0)

"""
Thickness e.g. of a line or stroke.
"""
@field Thickness = 2f0
@field Vertices = error("Needs default")
