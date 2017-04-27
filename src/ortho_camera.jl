using FieldTraits, GeometryTypes, Visualize, FileIO
using FieldTraits: @reactivecomposed, @field, Field, UsageError, @needs, Composable
import FieldTraits: on, Fields, Links, NoUpdate
using Visualize: WindowEvents, add!, Mouse, Window, default, translationmatrix, Keyboard
using Visualize: Camera, orthographicprojection, IRect, FRect, ispressed, View, Area
import Base: RefValue
using ModernGL

events = WindowEvents()
for elem in (Mouse.Position, Mouse.Buttons, Mouse.Drag, Area, Keyboard.Buttons)
    add!(events, elem)
end

@async begin
    while isopen(events[Window])
        try
            GLWindow.poll_glfw()
        catch e
            warn(e)
        end
        yield()
    end
    GLFW.DestroyWindow(events[Window])
end


wscale(screenrect, viewrect) = widths(viewrect) ./ widths(screenrect)

function update_cam!(cam, area)
    x, y = minimum(area)
    w, h = widths(area) ./ 2f0
    cam.area = IRect(area.x, area.y, area.w, area.h)
    cam.projection = orthographicprojection(-w, w, -h, h, -10_000f0, 10_000f0)
    cam.view = translationmatrix(Vec3f0(-x - w, -y - h, 0))
    return
end

function add_pan!(cam::Camera, window)
    on(window, Mouse.Drag, RefValue(Vec(0.0, 0.0))) do dragging, startpos
        mp = Vec(window[Mouse.Position])
        if dragging == Mouse.down
            startpos[] = mp
        elseif dragging == Mouse.pressed && ispressed(window, Mouse.middle)
            diff = startpos[] .- mp
            a = cam[Area]
            st = diff .* wscale(window[Area], a)
            update_cam!(cam, FRect(minimum(a) .+ st, widths(a)))
        end
        nothing
    end
end

function selection_rect(
        canvas,
        key = Mouse.left,
        button = Set([Keyboard.left_control, Keyboard.space])
    )
    @needs canvas: (Mouse.Drag, Mouse.Position)
    rect = IRect(0, 0, 0, 0)
    lw = 2f0
    rect_vis = visualize(
        Primitive => rect,
        Pattern => [0.0, lw, 2lw, 3lw, 4lw],
        Thickness => lw,
        Color => RGBA(0.7f0, 0.7f0, 0.7f0, 0.9f0)
    )
    dragged_rect = on(canvas, Mouse.Drag) do drag
        if ispressed(canvas, key) && ispressed(canvas, button)
            if drag == Mouse.down
                rect_vis[Visible] = true # start displaying
                rect_vis[Primitive] = IRect(canvas[Mouse.Position], 0, 0)
            elseif drag == Mouse.pressed
                min = minimum(rect_vis[Primitive])
                wh = canvas[Mouse.Position] - min
                rect_vis[Primitive] = IRect(min, wh)
            end
        else
            # always hide if not the right key is pressed
            rect_vis[Visible] = false # hide
        end
        return
    end
    push!(canvas, rect_vis)
    rect_vis
end


function reset!(cam, boundingbox, preserveratio = true)
    w1 = widths(boundingbox)
    if preserveratio
        w2 = widths(cam[Screen][Area])
        ratio = w2 ./ w1
        w1 = if ratio[1] > ratio[2]
            s = w2[1] ./ w2[2]
            Vec2f0(s * w1[2], w1[2])
        else
            s = w2[2] ./ w2[1]
            Vec2f0(w1[1], s * w1[1])
        end
    end
    p = minimum(w1) .* 0.001 # 2mm padding
    update_cam!(cam, FRect(-p, -p, w1 .+ 2p))
    nothing
end

cam = Camera()
add_pan!(cam, events)
cam[View]
Keyboard
