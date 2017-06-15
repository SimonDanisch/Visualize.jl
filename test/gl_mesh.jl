using Visualize, GeometryTypes, Colors, ModernGL, FileIO

window = Visualize.GLRasterization.glwindow(Light => Light(Position => Vec3f0(10)))

# Create a functor
catmesh = normalmesh(load(Pkg.dir("GLVisualize", "assets", "cat.obj")))
catmesh = Base.view(
    reinterpret(Visualize.VertexN, catmesh.parent), catmesh.indexes[1]
)
mesh = Mesh(Vertices => catmesh)


draw_cat = visualize(window, mesh)

@async renderloop(window)
