using Visualize, GeometryTypes
using Base.Test
using Visualize: add!, PerspectiveCamera, TranslationSpeed, LookAt, EyePosition, Rotation, Area, RotationSpeed
using Visualize: Mouse, Pan, View, Projection, Translation, Rotation, Keyboard
using Visualize.GLRasterization: GLFWWindow

window = GLFWWindow()
for event in Visualize.NativeWindowEvents
    add!(window, event)
end

cam = PerspectiveCamera(
    TranslationSpeed => 1f0,
    LookAt => Vec3f0(0),
    EyePosition => Vec3f0(6, 6, 8),
    Rotation => Vec3f0(0),
    Area => window[Area],
    RotationSpeed => 0.1f0
)

add!(cam, Translation, window,
    Mouse.right, Set([Keyboard.left_control])
)
add!(cam, Rotation, window,
    Mouse.left, Set([Keyboard.left_control])
)
add!(cam, Projection, View)
add!(cam, EyePosition, LookAt)
