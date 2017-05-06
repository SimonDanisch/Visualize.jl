using GeometryTypes, StaticArrays, ModernGL
import GLAbstraction, GLWindow, ColorVectorSpace
using Transpiler, Visualize

vertex_main(vertex) = vertex

function geometry_main(emit!, vertex_out)
    pos = vertex_out[1]
    quad = Vec4f0(pos[1], pos[2], pos[1] + 0.4f0, pos[2] + 0.4f0)
    v1 = quad[Vec(1, 2)]
    v2 = quad[Vec(1, 4)]
    v3 = quad[Vec(3, 2)]
    v4 = quad[Vec(3, 4)]
    emit!(Vec4f0(v1[1], v1[2], 0f0, 1f0), Vec4f0(1, 0, 0, 1))
    emit!(Vec4f0(v2[1], v2[2], 0f0, 1f0), Vec4f0(1, 0, 0, 1))
    emit!(Vec4f0(v3[1], v3[2], 0f0, 1f0), Vec4f0(1, 0, 0, 1))
    emit!(Vec4f0(v4[1], v4[2], 0f0, 1f0), Vec4f0(1, 0, 0, 1))
    return
end
function fragment_main(geom_out)
    (geom_out,)
end
N = 20
vertices = Point2f0[(sin(2pi * (i / N)) , cos(2pi * (i / N))) for i = 1:N]


w = GLWindow.create_glcontext(debugging = true)

emit_placeholder(position, fragout) = nothing;

argtypes = (Vec2f0,)
vsource, vertexout = Transpiler.emit_vertex_shader(vertex_main, argtypes)

argtypes = (typeof(emit_placeholder), vertexout)
gsource, geomout = Transpiler.emit_geometry_shader(geometry_main, argtypes)
argtypes = (geomout,)
fsource, fragout = Transpiler.emit_fragment_shader(fragment_main, argtypes)
write(STDOUT, vsource)
println()
write(STDOUT, gsource)
println()
write(STDOUT, fsource)

vshader = GLAbstraction.compile_shader(vsource, GL_VERTEX_SHADER, :particle_vert)
gshader = GLAbstraction.compile_shader(gsource, GL_GEOMETRY_SHADER, :particle_geom)
fshader = GLAbstraction.compile_shader(fsource, GL_FRAGMENT_SHADER, :particle_frag)


program = compile_program(vshader, gshader, fshader)
buff = GLBuffer(vertices)
vbo = Visualize.VertexArray(buff, -1, 0);
glUseProgram(program)
glDisable(GL_CULL_FACE)
glDisable(GL_DEPTH_TEST)
glDisable(GL_BLEND)
glClearColor(0, 0, 0, 0)
glBindVertexArray(vbo.id)
while isopen(w)
    GLWindow.poll_glfw()
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glDrawArrays(GL_POINTS, 0, length(vertices))
    GLWindow.swapbuffers(w)
end
GLFW.DestroyWindow(w)
