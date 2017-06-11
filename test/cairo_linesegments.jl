using Cairo, GeometryTypes, Visualize
using Visualize: LineVertex, STDCanvas, LineUniforms, vert_linesegments

resolution = (1024, 1024)
scale = 20f0
middle = Vec2f0(resolution) ./ 2f0
radius = Float32(min(resolution...) ./ 2f0) - scale
N = 32
vertices = [LineVertex(
    Vec2f0((sin(2pi * (i / N)) , cos(2pi * (i / N)))) * radius .+ middle,
    scale,
    Vec4f0(1, i/N, 0, 1),
) for i = 1:N]
proj = orthographicprojection(SimpleRectangle(0, 0, resolution...), -10_000f0, 10_000f0)
uniforms = LineUniforms(
    eye(Mat4f0),
    20f0,
    4f0,
)
canvas = STDCanvas(
    proj,
    eye(Mat4f0),
    proj,
    resolution
)


vbo = reinterpret(NTuple{2, eltype(vertices)}, vertices)

c = CairoRGBSurface(resolution...);
cr = CairoContext(c);
save(cr);
set_source_rgb(cr, 1.0, 1.0, 1.0);    # light gray
rectangle(cr, 0.0, 0.0, resolution...); # background
fill(cr);
restore(cr);

save(cr);
## original example, following here

dashes = [50.0,  # ink
          10.0,  # skip
          10.0,  # ink
          10.0   # skip
          ];
#ndash = length(dashes); not implemented as ndash on set_dash
offset = -50.0;

set_dash(cr, dashes, offset);





## mark picture with current date
write_to_pdf(c, "sample_dash.pdf");
pwd()
