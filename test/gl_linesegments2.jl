using Iterators
using GeometryTypes, Visualize, Colors
using Visualize: Resolution, Open, Visible
using Visualize.GLRasterization: glwindow, renderloop
using Visualize: Model, Color, Position, LineVertex, LineSegments, Camera, BasicCamera

resolution = (1024, 1024)

window = glwindow(
    Resolution => resolution,
    Camera => BasicCamera(),
    Visualize.Debugging => true
);

scale = 10f0
res = Vec2f0(resolution)
radius = (min(resolution...) / 2f0) - scale

N = 32

x = LineSegments(Position => rand(Vec2f0, N))
Visualize.visualize(window, x)

@async renderloop(window)
