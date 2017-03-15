# This is the kind of API I'm aiming for!

canvas((0:h, 0:w)) do c
    ps = visualize!(c, points)
    on(Click, c, ps) do clicked, idx
        color = clicked ? colorant"red" : colorant"blue"
        ps[Color] = color
        ps[Position][idx] += 1
    end
    ps2 = visualize(c, image1)
    on(Mouse, c, zeros(Point2f0, 10)) do position, poly
        canvas((position - 50, 50, 50)) do c
            for (i, t) in enumerate(linspace(0, 2pi, length(poly)))
                poly[i] = Point2f0(cos(t), sin(t)) .* rand(0.8:0.01:1.2)
            end
            visualize(c, GLPlainMesh(poly))
        end
    end
    cat = visualize!(c, loadasset("cat.obj"))
    slider = slider(0:0.1:2pi) do val
        rotate!(cat, XAxis, val)
        scale!(cat, val)
    end
    plottingpane = canvas(
        (0:100, 0:100, 0:100),
        (log, log, identity)
    )

    map(plottingpane, Camera) do c
        grids(c, cam)

        scatter(c, points)

        annotations(c, cam)
        labels(c, cam)
    end

end
