

@field Screen begin
    function Screen(dictlike = Empty())
        area = get(dictlike, Area, Area)
        currentbackend().framebuffer(area)
    end
end


@field Rotation begin
    Rotation = Quaternion(1, 0, 0, 0)
end
@field Scale begin
    Scale = Vec3f0(1)
end
@field Position begin
    Position = Vec3f0(0)
end

@field XAxis
@field YAxis
@field ZAxis

"""
The Area something is view in. Can be a Rectangle or a tuple with two elements.
"""
@field Area begin
    # TODO adjust to screen resolution
    Area = (500, 500)
end

@field Spacetransform begin
    Spacetransform = (identity, identity, identity)
end

@field Projection


@field Primitive


@composed type Transform
    Scale
    Rotation
    Position
end

@composed type Camera
    Area
    View

end

@composed type Canvas
    WindowEvents
    Screen
    Area
    Spacetransform
    Transform
    Projection
    Links
end



function default(::Type{T}, ::Type{Spacetransform})
    (identity, identity, identity)
end

function default{T <: Composable}(::Type{T}, ::Type{Spacetransform})
    (identity, identity, identity)
end

#############################################
# Most basic api that all composed types should support

function Base.scale!{N}(c::Composable, val::NTuple{N, Number})
    c[Scale] = val
    nothing
end
function translate!{N}(c::Composable, val::NTuple{N, Number})
    c[Position] = val
    nothing
end

# TODO allow also Vec2, Vec3, Axis + Float.
# This will be done by implementing symmetric transforms on the Rotation field type
function rotate!(c::Composable, val::Quaternion)
    c[Rotation] = val
    nothing
end
