using GeometryTypes, StaticArrays, ModernGL, Visualize
import GLAbstraction, GLWindow, ColorVectorSpace
import Transpiler: mix, smoothstep, gli
using Visualize: orthographicprojection, perspectiveprojection, lookat, normalmesh

function blinnphong2{NV, T}(V, N, L::Vec{NV, T}, color, ambient, light)
    diff_coeff = 2.3f0
    specular_power = 3.0f0
    specular = Vec3f0(0, 2, 3)
    spec_coeff = 0.77f0

    return ambient .* ambient .+
        color .* 1f0 .* color * diff_coeff .+
        specular .* specular_power .* specular * spec_coeff
end


# args = (Vec3f0(0), Vec3f0(0,1.5,3), Vec3f0(3), Vec3f0(1, 0, 0), shading, light)
# V, N, L, color, shading, light = args
# blinnphong2(args...)
# using Sugar, Transpiler
# m = Transpiler.GLMethod((blinnphong2, map(typeof, args)))
# ast = Sugar.getsource!(m)
# println(ast)
#
# ft = Sugar.expr_type(m, SlotNumber(13))
# args = map(x-> Sugar.expr_type(m, SSAValue(x)), 9:11)
# F = Sugar.instance(ft)
# typs = Tuple{ft, args...}
# m2 = Transpiler.GLMethod((broadcast, typs))
# ast2 = Sugar.sugared(m2.signature...)
# s2 = Sugar.getast!(m2)
# println(s2)
# Sugar.method_nargs(m2)
# @which Sugar.slotnames(m2)
# Sugar.getcodeinfo!(m2).slotnames
#
# F = Sugar.expr_type(m, SSAValue(0)).instance
#
