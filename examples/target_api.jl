# Low level api:

canvas((0:h, 0:w)) do c
    #
    ps = visualize!(c, points) #
    # change color of point viz when clicked on a point
    on(Click, c, ps) do clicked, idx
        color = clicked ? colorant"red" : colorant"blue"
        ps[Color] = color
        ps[Position][idx] += 1
    end
    # Create a polygon which folows the mouse
    on(Mouse, c, zeros(Point2f0, 10)) do position, poly
        canvas((position - 50, 50, 50)) do c
            for (i, t) in enumerate(linspace(0, 2pi, length(poly)))
                poly[i] = Point2f0(cos(t), sin(t)) .* rand(0.8:0.01:1.2)
            end
            visualize(c, GLPlainMesh(poly))
        end
    end
    cat = visualize!(c, loadasset("cat.obj"))
    # rotate and scale a visualization via a slider
    slider = slider(0:0.1:2pi) do val
        rotate!(cat, XAxis, val)
        scale!(cat, val)
    end
    # create a canvas with a space transform, that applyes log to x,y and leaves z untouched
    plottingpane = canvas(
        (0:100, 0:100, 0:100),
        (log, log, identity)
    )
    # this whill change grids, annotations and labels whenever the camera changes!
    on(plottingpane, Camera) do c
        grids(c, cam) # display a grid
        scatter(c, points) # display a scatter

        annotations(c, cam) # etc
        labels(c, cam)
    end

end
