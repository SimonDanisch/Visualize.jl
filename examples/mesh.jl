using Visualize
using Visualize: orthographicprojection, perspectiveprojection, lookat, normalmesh, JLCanvas, Area, JLRasterizer, Framebuffer
using FileIO, Images, GeometryTypes
include(Visualize.dir("src", "julia","mesh.jl"))

catmesh = normalmesh(load(Pkg.dir("GLVisualize", "assets", "cat.obj")))
catmesh = Base.view(reinterpret(MeshRender.Vertex, catmesh.parent), catmesh.indexes[1])
proj = perspectiveprojection(42f0, 1f0, 0.1f0, 10f0)
view = lookat(Vec3f0(1.5), Vec3f0(0.5), Vec3f0(0, -1, 0))
solid_color = Vec3f0(0.0, 0.7, 1.0)

light = MeshRender.Light(
    Vec3f0(10),
    Vec3f0(0.0),
    Vec3f0(0.9),
    1.0f0,
    Vec3f0(0.2),
    1.0f0
)
shading = MeshRender.Shading(
    Vec3f0(0.0),
    Vec3f0(0.3),
    8.0f0
)

program_args = (light, shading, (solid_color, proj, view))
canvas = JLCanvas(Area => SimpleRectangle(0, 0, 500, 500))

draw = JLRasterizer(
    catmesh, program_args,
    MeshRender.vertexshader, MeshRender.fragmentshader,
)

@time draw(canvas, catmesh, program_args)

save("test.png", clamp01.(canvas[Framebuffer][1]))
