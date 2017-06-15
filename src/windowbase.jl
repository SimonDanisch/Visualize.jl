@field ColorBuffer
@field DepthBuffer

@field Model = eye(Mat4f0)
@field Renderlist = []
@field NativeWindow = nothing
"""
Holds general attribute of the scene/window, like camera uniforms and lights.
"""
@field Scene = nothing
@field Canvas = nothing

abstract type AbstractScene <: ReactiveComposable end
abstract type AbstractCanvas <: ReactiveComposable end

@reactivecomposed type JLCanvas <: AbstractCanvas
    Area
    DepthBuffer
    ColorBuffer
end

function default(::Type{DepthBuffer}, canvas::Partial{<: AbstractCanvas})
    w, h = widths(get(canvas, Area))
    ones(Float32, w, h)
end

function default(::Type{ColorBuffer}, canvas::Partial{<: AbstractCanvas})
    w, h = widths(get(canvas, Area))
    (zeros(RGBA{Float32}, w, h), )
end


@field Ambient = Vec3f0(0.1)
@field Diffuse = Vec3f0(0.0)
@field DiffusePower = 1f0
@field Specular = Vec3f0(0.3)
@field SpecularPower = 10f0


@composed type Light
    Position::Vec3f0
    Ambient::Vec3f0
    Diffuse::Vec3f0
    DiffusePower::Float32
    Specular::Vec3f0
    SpecularPower::Float32
end

@composed type Window <: AbstractWindow
    <: WindowEvents
    NativeWindow
    Camera
    Renderlist
    Scene
    Color
    Light # TODO Move into Scene, but can't since struct of structs isn't supported very well yet
end
function default(::Type{Scene}, p::Partial{<: AbstractWindow})
    cam = get!(p, Camera)
    scene = SceneUniforms(cam)
    for field in FieldTraits.Fields(scene)
        if haskey(cam, field)
            FieldTraits.link!(field, cam => scene)
        end
    end
    return scene
end

Base.isopen(window::AbstractWindow) = window[Open]


function getmultiple!(field, parent, tail...)
    i = start(tail)
    head = parent
    while true
        haskey(head, field) && return get!(head, field)
        if done(tail, i)
            def = default(field, parent)
            parent[field] = def
            return def
        end
        head, i = next(tail, i)
    end
end

# function default{AC <: AbstractScene}(::Type{AC}, p::Partial{Window})
#     cam = get!(p, Camera)
#     AC(map(field-> getmultiple!(field, p, cam), Fields(AC)))
# end




# Basic functions a window should defined
function show!(window::AbstractWindow)
    error("Not implemented for $(typeof(window))")
end
function destroy!(window::AbstractWindow)
    error("Not implemented for $(typeof(window))")
end
function swapbuffers!(window::AbstractWindow)
    error("Not implemented for $(typeof(window))")
end
function renderloop(window::AbstractWindow)
    error("Not implemented for $(typeof(window))")
end
