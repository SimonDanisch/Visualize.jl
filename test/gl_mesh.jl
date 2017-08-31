using Transpiler, GeometryTypes, StaticArrays

function vert_image(vertex, args)
    p, uv = vertex
    proj = args[1]
    position = proj * Vec{4, eltype(p)}(p[1], p[2], 0f0, 1f0)
    position, (uv,)
end
function frag_image(fragment_in, args)
    uv, = fragment_in
    image = args[2]
    color = image[uv]
    (color,)
end


vertex = Vec2f0(0), Vec2f0(0)
args = (eye(Mat4f0),)
vert_image(vertex, args)
src, typ = Transpiler.emit_fragment_shader(vert_image, (typeof(vertex), typeof(args)))
write(STDOUT, src)

using Transpiler: GLMethod
using Sugar
x = GLMethod((vert_image, Tuple{typeof(vertex), typeof(args)}))
rasterizer(
    window,
    vbo, args,
    vert_linesegments, frag_linesegments;
    geometryshader = geom_linesegments,
    primitive_in = :lines
)
