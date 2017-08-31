using Visualize, GeometryTypes, ModernGL
using Visualize: GLRasterization, Uniforms, VertexCS, get_texture_atlas, Sprite2
using Visualize: orthographicprojection, perspectiveprojection, lookat, normalmesh, ColorBuffer, Area
using Visualize.JLRasterization: JLCanvas, JLRasterizer
resolution = (1024, 1024)
canvas = JLCanvas((Area => SimpleRectangle(0, 0, resolution...),))


proj = orthographicprojection(SimpleRectangle(0, 0, resolution...), -10_000f0, 10_000f0)

uniforms = Uniforms(
    proj,
    Vec4f0(1, 0, 0, 1),
    Vec4f0(1, 0, 1, 1),
    Visualize.circle
)

N = 20
middle = Vec2f0(resolution) / 2f0
radius = min(resolution...) / 2f0
vertices = [(VertexCS(
    Vec2f0((sin(2pi * (i / N)) , cos(2pi * (i / N))) .* radius) .+ middle,
    Vec4f0(1, i/N, 0, 1),
    Vec2f0(40, 40)
),) for i = 1:N]
Visualize.visualize(canvas, x)

visualize(canvas, )
using FileIO, Images
save(joinpath(homedir(), "Desktop/test.png"), clamp01.(canvas[Visualize.ColorBuffer][1]))
