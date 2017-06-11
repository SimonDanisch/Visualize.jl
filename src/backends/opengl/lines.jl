using FieldTraits
using FieldTraits: @composed, @field

@field Position
@field Color

@composed type GLLineSegments
    Position
    Color
end

using Iterators
using GeometryTypes, Sugar, Transpiler
using Transpiler

function test(x)
    haskey(x, Color)
end

x = GLLineSegments(
    (Position => Vec2f0(0),
    Color => Vec4f0(1))
)
@which haskey(x, Color)

m = Transpiler.GLMethod((test, Tuple{typeof(x)}))
test(x)

@code_llvm(test(x))

println(Sugar.getsource!(m))

function convertfor(::Type{VBO}, p::Partial{GLLineSegments})
    p
end
