module Visualize

using Colors, StaticArrays, Quaternions, FieldTraits
using Compat, GLWindow, GLFW
using GeometryTypes, Quaternions

using FieldTraits: @reactivecomposed, @field, Field, UsageError, @needs, Composable
import FieldTraits: on, Fields, Links, @composed, default, ReactiveComposable

import Base: scale!

include("math.jl")
include("base.jl")
include("windowbase.jl")
include("events.jl")
include("images.jl")

#include("opengl/opengl.jl")


end # module
