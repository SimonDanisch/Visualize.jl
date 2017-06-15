function scale!{N}(c::Composable, val)
    c[Scale] = val
    return
end
function translate!{N}(c::Composable, val)
    c[Position] = val
    return
end

# TODO allow also Vec2, Vec3, Axis + Float.
# This will be done by implementing symmetric transforms on the Rotation field type
function rotate!(c::Composable, val)
    c[Rotation] = val
    return
end
