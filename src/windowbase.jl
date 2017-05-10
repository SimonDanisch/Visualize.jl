@composed type Canvas <: ReactiveComposable
    <: Shared
    Window
    Camera
    Spacetransform
end

@field ColorBuffer
@field DepthBuffer
