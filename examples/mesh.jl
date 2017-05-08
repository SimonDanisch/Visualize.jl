using Visualize
using Visualize: orthographicprojection, perspectiveprojection, lookat, normalmesh

include(Visualize.dir("julia", "mesh.jl"))

catmesh = normalmesh(load(Pkg.dir("GLVisualize", "assets", "cat.obj")))
proj = perspectiveprojection(42f0, 1f0, 0.1f0, 10f0)
view = lookat(Vec3f0(1.5), Vec3f0(0.5), Vec3f0(0, -1, 0))

framebuffer = ones(RGB{Float32}, 1024, 1024)
depthbuffer = ones(Float32, size(framebuffer))
solid_color = Vec3f0(0.0, 0.7, 1.0)

light = Light(
    Vec3f0(10),
    Vec3f0(0.0),
    Vec3f0(0.9),
    1.0f0,
    Vec3f0(0.2),
    1.0f0
)
shading = Shading(
    Vec3f0(0.0),
    Vec3f0(0.3),
    8.0f0
)

program_args = (light, shading, (solid_color, proj, view))
rasterize!(
    depthbuffer, (framebuffer,),
    catmesh, program_args,
    MeshRender.vertexshader, MeshRender.fragmentshader
)

using FileIO, Images
save("test.png", clamp01.(framebuffer))
