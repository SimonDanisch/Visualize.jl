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

@composed type Window <: AbstractWindow
    <: WindowEvents
    NativeWindow
    Camera
    Renderlist
    Scene
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
