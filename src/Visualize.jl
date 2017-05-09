module Visualize

using Colors, ColorVectorSpace, StaticArrays, Quaternions, FieldTraits
using Compat, GLWindow, GLFW
using GeometryTypes, Quaternions
using Interpolations, FileIO


using FieldTraits: @reactivecomposed, @field, Field, UsageError, @needs, Composable, ComposableLike
import FieldTraits: on, Fields, Links, @composed, default, ReactiveComposable

import Base: scale!

"""
Replacement of Pkg.dir("Visualize") --> Visualize.dir,
returning the correct path
"""
dir(dirs...) = joinpath(normpath(dirname(@__FILE__), ".."), dirs...)

include("math.jl")
include("base.jl")
include("windowbase.jl")
include("events.jl")
include("images.jl")
include("perspective_camera.jl")

include("julia/rasterpipeline.jl")
include("opengl/opengl.jl")

end # module
