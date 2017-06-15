using Cairo, GeometryTypes, Visualize
using Visualize: CairoWindow, AbstractCairoWindow, Canvas, Scene, ColorBuffer, DepthBuffer, clip2pixel_space, CairoContext
using Visualize.JLRasterization: JLRasterizer, edge_function, interpolate,standard_transparency, broadcastmin, broadcastmax
using FileIO, GeometryTypes, Colors
using Visualize: normalmesh, Light, Shading, MeshUniforms, Camera, visualize, Vertices, AbstractCairoWindow, FRect

window = CairoWindow(Camera => BasicCamera())

canvas = window[Canvas]
x = canvas[Visualize.CairoSurface]
y = canvas[Visualize.CairoContext]

resolution = (1024, 1024)

x = LineSegments(Position => rand(Vec2f0, 32), Color => Vec4f0(1, 1, 1, 1))

empty!(window[Visualize.Renderlist])

visualize(window, x)
Visualize.draw_window!(window)
Cairo.write_to_png(canvas[Visualize.CairoSurface], homedir()*"/Desktop/test.png")
