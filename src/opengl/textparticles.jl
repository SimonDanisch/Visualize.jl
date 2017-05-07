using GeometryTypes, StaticArrays, ModernGL, Visualize
import GLAbstraction, GLWindow, ColorVectorSpace
import Transpiler: mix, smoothstep, gli
using Visualize: orthographicprojection, VertexArray, UniformBuffer, get_texture_atlas

function aastep{T}(threshold1::T, value)
    smoothstep(threshold1 - T(0.1), threshold1 + T(0.1), value)
end

type Uniforms
    projection::Mat4f0
    strokecolor::Vec4f0
    glowcolor::Vec4f0
end
immutable Vertex2Geom
    uv::Vec4f0
    color::Vec4f0
    rect::Vec4f0
end


abstract Particle
immutable Sprite{N, T} <: Particle
    position::Point{N, T}
    offset::Vec{2, T}
    scale::Vec{2, T}
    uv::Vec{4, T}
    color::Vec{4, T}
end
const GLSprite2 = Sprite{2, Float32}
const GLSprite3 = Sprite{3, Float32}

function Sprite{N, T}(
        char, position::Point{N, T}, text
    )
    Sprite(
        char, position, text.scale, text.offset,
        text.color, text.font, text.atlas
    )
end
function Sprite{N, T}(
        char, position::Point{N, T}, scale, offset, color,
        font = defaultfont(),  atlas = get_texture_atlas()
    )
    Sprite{N, T}(
        position,
        glyph_bearing!(atlas, char, font, scale) + offset,
        glyph_scale!(atlas, char, font, scale),
        glyph_uv_width!(atlas, char, font),
        color
    )
end
include(Pkg.dir("Visualize", "src", "opengl", "textoperations.jl"))


function vertex_main(vertex, uniforms, image)
    p = vertex.position .+ vertex.offset
    scale = vertex.scale
    geom = Vertex2Geom(
        vertex.uv,
        vertex.color,
        Vec4f0(p[1], p[2], scale[1], scale[2])
    )
    Vec4f0(0), geom
end

"""
Emits a vertex with
"""
function emit_vertex(emit!, vertex, offsetted_uv, arg, pos, uniforms)
    datapoint = uniforms.projection * Vec4f0(pos[1], pos[2], 0, 1)
    final_position = uniforms.projection * Vec4f0(vertex[1], vertex[2], 0, 0)
    frag_out = (offsetted_uv, arg.color)
    emit!(datapoint .+ final_position, frag_out)
    return
end

function geometry_main(emit!, vertex_out, uniforms, image)
    # get arguments from first face
    # (there is only one in there anywas, since primitive type is point)
    # (position, vertex_out)
    arg = vertex_out[1]
    # emit quad as triangle strip
    # v3. ____ . v4
    #    |\   |
    #    | \  |
    #    |  \ |
    #    |___\|
    # v1*      * v2
    pos_scale = arg.rect
    pos = pos_scale[Vec(1, 2)]
    scale = pos_scale[Vec(3, 4)]
    quad = Vec4f0(0f0, 0f0, scale[1], scale[2])
    uv = arg.uv
    emit_vertex(emit!, quad[Vec(1, 2)], uv[Vec(1, 4)], arg, pos, uniforms)
    emit_vertex(emit!, quad[Vec(1, 4)], uv[Vec(1, 2)], arg, pos, uniforms)
    emit_vertex(emit!, quad[Vec(3, 2)], uv[Vec(3, 4)], arg, pos, uniforms)
    emit_vertex(emit!, quad[Vec(3, 4)], uv[Vec(3, 2)], arg, pos, uniforms)
    return
end
function fragment_main(geom_out, uniforms, image)
    uv_offset = geom_out[1]; color = geom_out[2];
    signed_distance = -image[uv_offset][1]
    inside = aastep(0f0, signed_distance)
    bg = Vec4f0(1f0, 1f0, 1f0, 0f0)
    (mix(bg, color, inside),)
end

resolution = (500, 500)
w = GLWindow.create_glcontext(resolution = resolution)

proj = orthographicprojection(SimpleRectangle(0, 0, resolution...), -10_000f0, 10_000f0)
uniforms = Uniforms(
    proj,
    Vec4f0(1, 0, 0, 1),
    Vec4f0(1, 0, 1, 1)
)

atlas = get_texture_atlas(w);

text = Text(
    GLSprite2[],
    Char[],
    atlas,
    [0],
    Visualize.defaultfont(),
    45f0,
    0f0,
    Vec4f0(0f0, 0f0, 0f0, 1f0),
    Point2f0(0),
    1.5
);

print(text, 'c')
print(text, " lololol")
text.color = Vec4f0(1f0, 0f0, 0f0, 1f0)
print(text, " Muashahahaha@")

uniform_buff = UniformBuffer(uniforms);
vbo = VertexArray(text.data);

draw_particles = GLRasterizer(
    vbo, (uniform_buff, atlas.images),
    vertex_main, fragment_main;
    geometry_main = geometry_main
)
glDisable(GL_DEPTH_TEST)
glClearColor(1, 1, 1, 0)
GLAbstraction.enabletransparency()

while isopen(w)
    GLWindow.poll_glfw()
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    draw_particles(vbo, (uniform_buff, atlas.images))
    GLWindow.swapbuffers(w)
end
GLFW.DestroyWindow(w)
