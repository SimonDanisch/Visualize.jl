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

end # module
