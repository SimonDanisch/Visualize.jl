__precompile__(true)
module Visualize

using Compat, FileIO, FieldTraits

using FieldTraits: @reactivecomposed, @field, @composed, @needs
using FieldTraits: Composable, ComposableLike, Field, UsageError, Fields, Links
using FieldTraits: ReactiveComposable
import FieldTraits: on, default

using Colors, ColorVectorSpace, StaticArrays
using GeometryTypes, Quaternions
using Interpolations

import GLAbstraction, ColorVectorSpace
import Transpiler: gli
import Transpiler: mix, smoothstep

import Base: scale!

"""
Replacement of Pkg.dir("Visualize") --> Visualize.dir,
returning the correct path
"""
dir(dirs...) = joinpath(normpath(dirname(@__FILE__), ".."), dirs...)

include("math.jl")
include("utils.jl")
include("base.jl")
include("events.jl")

include("camera.jl")
include("windowbase.jl")

include("shader/base.jl")
include("images.jl")
include("text/textbase.jl")


include("backends/julia/base.jl")
include("backends/cairo/base.jl")
include("backends/webgl/base.jl")
include("backends/opengl/base.jl")




using .GLRasterization
using .JLRasterization

export orthographicprojection, perspectiveprojection, lookat
export normalmesh, uvmesh, JLCanvas, JLRasterizer, Area, Framebuffer
export add!, PerspectiveCamera, TranslationSpeed, LookAt, EyePosition
export RotationSpeed, Translation, Rotation, Keyboard, WindowEvents, Window
export Mouse, Pan, View, Projection, IRect, Sampler, isopen


end # module
