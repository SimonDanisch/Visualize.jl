# Created by inigo quilez - iq/2013
# License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

# Volumetric clouds. It performs level of detail (LOD) for faster rendering and antialiasing
using MacroTools
using Visualize, GeometryTypes
using Visualize.JLRasterization: Sampler, JLCanvas, JLRasterizer
using Transpiler: mix, fract

Base.one(::Type{Vec3f0}) = Vec3f0(0f0, 0f0, 0f0)

"""
Unroll macro!
There is an unregistered package doing exactly this, called Unroll.jl.
But where'd be the fun in using that
Turns:
```Julia
@unroll for i=1:3
    println(i)
end
```
Into:
```Julia
i = 1
println(i)
i = 2
println(i)
i = 3
println(i)
```
"""
macro unroll(expr)
    idx, range, body = @match expr begin
        for idx_ = range_
            body__
        end => (idx, range, body)
        matchal__ => error("Only for loops like `for i=1:3` are supported")
    end
    block = Expr(:block)
    # Here, eval only works for static expressions.
    # If this would be serious code, we should include some error handling
    for i = eval(range)
        # create a block expression, starting with the assignment of the (now constant)
        # integer to the idx variable, and splicing in the rest of the for body
        # $ splices in the actual value. idx -> a symbol that will turn into a variable
        # i -> the actual index integer
        push!(block.args, :($idx = $i), body...)
    end
    esc(block)
end

function noise(x::Vec3f0)
    p = floor(x)
    f = fract(x)
    f = broadcast(*, f, f)
    f = (3f0 - 2f0*f)
    f = broadcast(*, f, f)
    uv = (p[Vec(1,2)] + Vec2f0(37f0, 17f0) * p[3]) + f[Vec(1,2)]
    rg = Vec2f0(0)
    return -1f0 + 2f0 * mix(rg[1], rg[2], f[3])
end

#noise(Vec3f0(0.242)

@generated function LODaa{N}(p::Vec3f0, time::Float32, ::Val{N})
    result = []
    qf = (2.02f0, 2.03f0, 2.01f0, 2.02f0)
    for i=1:N
        push!(result, :(f += $(2f0^(-i)) * noise(q)))
        i != N && push!(result, :(q = q * $(qf[i])))
    end
    quote
        f = 0f0
        q = p - Vec3f0(0f0, 0f0, 1f0) * time
        $(result...) # splice in unrolled expressions
        res = (1.5f0 - p[2] - 2f0 + 1.75f0) * f
        clamp(res, 0f0, 1f0)
    end
end
#LODaa(rand(Vec3f0), 1f0, Val{5}())

function integrate(
        sum::Vec4f0, dif::Float32, den::Float32,
        bgcol::Vec3f0, t::Float32
    )
    # lighting
    lin = Vec3f0(0.65f0, 0.68f0, 0.7f0) * 1.3f0 + 0.5f0 *
        Vec3f0(0.7f0, 0.5f0, 0.3f0) * dif

    colo = mix(1.15f0 * Vec3f0(1f0, 0.95f0, 0.8f0), Vec3f0(0.65f0), den)
    colo = colo .* lin
    colo = mix(colo, bgcol, 1f0 - exp(-0.003f0 * t*t))
    # front to back blending
    alpha = den * 0.4f0
    colo *= alpha
    return sum .+ Vec4f0(colo[1], colo[2], colo[3], alpha) * (1f0 - sum[4])
end


#
# integrate(
#     Vec4f0(0.2, 0.5, 0.3, 0.8), 2f0, 0.4f0,
#     Vec3f0(0.5, 0.58, 0.9), 1f0
# )

function march{N}(ro, rd, bgcol, sundir, sumt, steps, n::Val{N})
    sum = sumt[1]
    t = sum[2]
    for i = 1:steps
        pos = ro + t * rd
        if (pos[2] < -3f0 || pos[2] > 2f0 || sum[4] > 0.99f0)
            break
        end
        den = LODaa(pos, 1f0, n)
        if den > 0.01f0
            dif = clamp(
                (den - LODaa(pos + 0.3f0 * sundir, 1f0, n)) / 0.6f0,
                0f0, 1f0
            )
            sum = integrate(sum, dif, den, bgcol, t)
        end
        t += max(0.1f0, 0.02f0 * t)
    end
    sum, t
end

# march(
#     Vec3f0(0), Vec3f0(0), Vec3f0(0),
#     normalize(Vec3f0(-1f0, 0f0, -1f0)),
#     Vec4f0(0f0), 0f0, 30, Val{5}()
# )

function raymarch(ro::Vec3f0, rd::Vec3f0, bgcol::Vec3f0, sundir::Vec3f0)
    sumt = (Vec4f0(0f0), 0f0)
    #@unroll for i = 5:-1:2
        sumt = march(ro, rd, bgcol, sundir, sumt, 30, Val{5}())
        sumt = march(ro, rd, bgcol, sundir, sumt, 30, Val{4}())
        sumt = march(ro, rd, bgcol, sundir, sumt, 30, Val{3}())
        sumt = march(ro, rd, bgcol, sundir, sumt, 30, Val{2}())
    #end
    sum = sumt[1]

    return Vec4f0(
        clamp(sum[1], 0f0, 1f0),
        clamp(sum[2], 0f0, 1f0),
        clamp(sum[3], 0f0, 1f0),
        clamp(sum[4], 0f0, 1f0),
    )
end

# raymarch(
#     Vec3f0(0), Vec3f0(0), Vec3f0(0),
#     normalize(Vec3f0(-1f0, 0f0, -1f0)),
# )
#
# @code_warntype(raymarch(
#     Vec3f0(0), Vec3f0(0), Vec3f0(0),
#     normalize(Vec3f0(-1f0, 0f0, -1f0)),
# ))


function render(ro::Vec3f0, rd::Vec3f0, sundir::Vec3f0)
    # background sky
    sun = clamp(dot(sundir, rd), 0f0, 1f0)
    col = Vec3f0(0.6f0, 0.71f0, 0.75f0) - rd[2] *
        0.2f0 * Vec3f0(1f0, 0.5f0, 1f0) + 0.15f0 * 0.5f0

    col += 0.2f0 * Vec3f0(1f0, .6f0, 0.1f0) * (sun ^ 8f0)

    # clouds
    res = raymarch(ro, rd, col, sundir)
    col = col * (1f0 - res[4]) + res[Vec(1,2,3)]

    # sun glare
    col += 0.1f0 * Vec3f0(1f0, 0.4f0, 0.2f0) * (sun ^ 3f0)

    return Vec4f0(col[1], col[2], col[3], 1f0)
end

#render(Vec3f0(0), Vec3f0(0), normalize(Vec3f0(-1f0, 0f0, -1f0)))
function camera(cr = 0f0)
    # camera
    ro = 4f0 * normalize(Vec3f0(sin(3f0 * 1f0), 0.4*1f0, cos(3.0 * 1f0)))
    ta = Vec3f0(0.0, -1.0, 0.0)
    cw = normalize(ta - ro)
    cp = Vec3f0(sin(cr), cos(cr), 0.0)
    cu = normalize(cross(cw, cp))
    cv = normalize(cross(cu, cw))
    return ro, Mat3f0(cu..., cv..., cw...)
end

function frag_main(p, roca)
    ro = roca[1]
    ca = roca[2]
    #p = ptupl[1]
    sundir = normalize(Vec3f0(-1f0, 0f0, -1f0))
    # ray
    rd = ca * normalize(Vec3f0(p[1], p[2], 1.5f0))
    (render(ro, rd, sundir),)
end

function vert_main(p, roca)
    Vec4f0(p[1], p[2], 0, 1), p
end


noise_sampler = Sampler(rand(Vec3f0, 512, 512))
typeof(noise_sampler)
ro, ca = camera()
canvas = JLCanvas(Area => IRect(0, 0, 512, 512))
mesh = uvmesh(SimpleRectangle(-1f0, -1f0, 2f0, 2f0))
draw = JLRasterizer(
    mesh, (ro, ca),
    vert_main, frag_main,
)

draw(canvas, mesh, (ro, ca))
using FileIO
fb = canvas[FieldTraits.Fields(canvas)[3]][1]
save("/home/s/Desktop/test.png", fb)


canvas = GLFWWindow()

rect = SimpleRectangle(-1f0, -1f0, 2f0, 2f0)
mesh = Base.view(decompose(Point2f0, rect), decompose(GLTriangle, rect))
ro, ca = camera()
vbo = VertexArray(mesh)
uniforms = UniformBuffer((ro, ca))
draw = GLRasterizer(
    mesh, (uniforms,),
    vert_main, frag_main,
)
