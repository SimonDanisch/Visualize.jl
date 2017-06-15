using Visualize, GeometryTypes
using Visualize: TextUniforms, get_texture_atlas, Sprite2
using Visualize: orthographicprojection, perspectiveprojection, lookat, normalmesh, ColorBuffer, Area
using Visualize.JLRasterization: JLCanvas, JLRasterizer

resolution = (1024, 1024)
canvas = JLCanvas(Area => SimpleRectangle(0, 0, resolution...))

proj = orthographicprojection(SimpleRectangle(0, 0, resolution...), -10_000f0, 10_000f0)
uniforms = TextUniforms(
    proj,
    Vec4f0(1, 0, 0, 1),
    Vec4f0(1, 0, 1, 1)
)

atlas = get_texture_atlas();

text = Visualize.Text(
    Sprite2[],
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

uniform_buff = uniforms
vbo = reinterpret(Tuple{eltype(text.data)}, text.data)
atlas_tex = atlas.images;

draw_particles = JLRasterizer(
    vbo, (uniform_buff, atlas_tex),
    Visualize.vertex_main, Visualize.fragment_main;
    geometryshader = Visualize.geometry_main
)
canvas = JLCanvas(Area => SimpleRectangle(0, 0, resolution...))
draw_particles(canvas, vbo, (uniform_buff, atlas_tex))
using FileIO, Images
save("test.png", clamp01.(canvas[Visualize.ColorBuffer][1]))
