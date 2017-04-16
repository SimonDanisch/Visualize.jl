function scale!{N}(c::Composable, val::NTuple{N, Number})
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
