using GeometryTypes, Visualize, Colors, GLAbstraction
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
ls = LineSegments((
    Position => [rand(Vec2f0) .* res for x in 1:N],
    Color => Vec4f0(1, 0,0,1)
))
ls
x = Visualize.visualize(window, ls)

renderloop(window)
window[Camera]
map(x-> window[Camera][ProjectionView] * Vec4f0(x..., 0, 1.0),  [rand(Vec2f0) .* res for x in 1:N])
# Visualize.destroy!(window)


using Visualize, GeometryTypes, Colors, FileIO, NIfTI

window = Visualize.GLRasterization.glwindow(
    Resolution => (1024, 1024),
    Visualize.Color => Vec4f0(0.0, 0.0, 0.0, 0.0),
)


niivol = Array(niread("/media/s/94BC3648BC362560/Users/sdani/juliastuff/demo/t2.nii"))
vol = niivol ./ maximum(niivol)

colorfun2(color, uniforms, intensities) = color

function accum2(accum, pos, stepdir, intensities, uniforms)
    alpha = intensities[pos][1] * 0.1f0
    sample = Vec4f0(0.9f0, 0f0, 0.4f0, alpha)
    alpha = 1f0 - ((1f0 - alpha) ^ 1.2f0)
    sample = Vec4f0(
        sample[1] * alpha,
        sample[2] * alpha,
        sample[3] * alpha,
        alpha
    )
    sample = (1f0 - accum[4]) * sample
    tmp = accum + sample
    tmp, tmp[4] > 0.95f0
end

volume = Visualize.Volume((
    Data => vol,
    AccumulationFunction => accum2,
    StartValue => Vec4f0(0),
    ColorFunction => colorfun2,
))

wf = wireframe(
    AABB(Vec3f0(-0.01), Vec3f0(1.02)), ()
)

visualize(window, wf)
visualize(window, volume)
@async renderloop(window)
