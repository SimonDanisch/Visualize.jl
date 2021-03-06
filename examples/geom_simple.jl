using GeometryTypes, StaticArrays, ModernGL
using Transpiler, Visualize

vertex_main(vertex) = vertex

function geometry_main(emit!, geom_in)
    pos = geom_in[1]
    quad = Vec4f0(pos[1], pos[2], pos[1] + 0.4f0, pos[2] + 0.4f0)
    v1 = quad[Vec(1, 2)]
    v2 = quad[Vec(1, 4)]
    v3 = quad[Vec(3, 2)]
    v4 = quad[Vec(3, 4)]
    emit!(Vec4f0(v1[1], v1[2], 0f0, 1f0), (Vec4f0(1, 0, 0, 1),))
    emit!(Vec4f0(v2[1], v2[2], 0f0, 1f0), (Vec4f0(1, 0, 0, 1),))
    emit!(Vec4f0(v3[1], v3[2], 0f0, 1f0), (Vec4f0(1, 0, 0, 1),))
    emit!(Vec4f0(v4[1], v4[2], 0f0, 1f0), (Vec4f0(1, 0, 0, 1),))
    return
end
fragment_main(fragment_in) = (fragment_in[1],)

N = 20
vertices = [(Point2f0(sin(2pi * (i / N)) , cos(2pi * (i / N))), ) for i = 1:N]
canvas = JLCanvas(Area => SimpleRectangle(0, 0, 500, 500))

draw = JLRasterizer(
    vertices, (),
    vertex_main, fragment_main,
    geometryshader = geometry_main
)
@time draw(canvas, vertices, ())

save("test.png", canvas[Visualize.ColorBuffer][1])
