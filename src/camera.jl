const Q = Quaternions

@enum ProjectionEnum Perspective Orthographic

@field RotationSpeed = 1f0
@field TranslationSpeed = 1f0
@field EyePosition = Vec3f0(3)
@field LookAt = Vec3f0(0)
@field UpVector = Vec3f0(0, 0, 1)
@field Fov = 45f0
@field Near = 0.01f0
@field Far = 100f0
@field ProjectionType = Perspective

abstract type AbstractCamera <: ReactiveComposable end

@field Camera

function default(::Type{Camera}, x::Partial)
    PerspectiveCamera(x.val)
end
function default(::Type{Area}, x::Partial{<: AbstractCamera})
    FRect(default(Area))
end

@reactivecomposed type BasicCamera <: AbstractCamera
    Area
    Projection
    View
    ProjectionView
end

@composed type PerspectiveCamera <: AbstractCamera
    <: BasicCamera
    ProjectionType
    Translation
    Rotation
    RotationSpeed
    TranslationSpeed
    EyePosition
    LookAt
    UpVector
    Fov
    Near
    Far
end

default(::Type{Rotation}, ::Partial{<: AbstractCamera}) = Vec3f0(0, 0, 0)

function add!(cam, ::Type{Translation}, canvas, key, button)
    local last_mousepos::Vec2f0 = Vec2f0(0, 0)
    on(canvas, Mouse.Drag) do drag
        if ispressed(canvas, key) && ispressed(canvas, button)
            if drag == Mouse.down
                #just started pressing, nothing to do yet
                last_mousepos = Vec2f0(canvas[Mouse.Position])
            elseif drag == Mouse.pressed
                 # we need the difference, although I'm wondering if absolute wouldn't be better.
                 # TODO FIND OUT! Definitely would have more precision problems
                mousepos = Vec2f0(canvas[Mouse.Position])
                diff = (last_mousepos - mousepos) * cam[TranslationSpeed]
                last_mousepos = mousepos
                cam[Translation] = Vec3f0(0f0, diff[1], - diff[2])
            end
        end
        return
    end
    on(canvas, Mouse.Scroll) do scroll
        if ispressed(canvas, button)
            cam[Translation] = Vec3f0(scroll[2], 0f0, 0f0)
        end
        return
    end
end
function add!(cam, ::Type{Rotation}, canvas, key, button)
    local last_mousepos::Vec2f0 = Vec2f0(0, 0)
    on(canvas, Mouse.Drag) do drag
        if ispressed(canvas, key) && ispressed(canvas, button)
            if drag == Mouse.down
                last_mousepos = Vec2f0(canvas[Mouse.Position])
            elseif drag == Mouse.pressed
                mousepos = Vec2f0(canvas[Mouse.Position])
                mp = (last_mousepos - mousepos) * cam[RotationSpeed]
                last_mousepos = mousepos
                cam[Rotation] = Vec3f0(mp[1], -mp[2], 0f0)
            end
        end
        return
    end
end
function add!(cam, ::Type{EyePosition}, ::Type{LookAt})
    on(cam, Translation) do translation
        translation == Vec3f0(0) && return

        lookat = cam[LookAt]; eyepos = cam[EyePosition]; up = cam[UpVector]
        projview = cam[ProjectionView]; area = cam[Area]; prjt = cam[ProjectionType]

        dir = eyepos - lookat
        dir_len = norm(dir)
        cam_res = Vec2f0(widths(area))
        zoom, x, y = translation
        zoom *= 0.1f0 * dir_len

        if prjt != Perspective
            x, y = to_worldspace(Vec2f0(x, y), projview, cam_res)
        else
            x, y = (Vec2f0(x, y) ./ cam_res) .* dir_len
        end
        dir_norm = normalize(dir)
        right = normalize(cross(dir_norm, up))
        zoom_trans = dir_norm * zoom

        side_trans = right * (-x) + normalize(up) * y
        newpos = eyepos + side_trans + zoom_trans
        cam[EyePosition] = newpos
        cam[LookAt] = lookat + side_trans
        return
    end
    on(cam, Rotation) do theta_v
        theta_v == Vec3f0(0) && return #nothing to do!
        eyepos_v = cam[EyePosition]; lookat_v = cam[LookAt]; up_v = cam[UpVector]

        dir = normalize(eyepos_v - lookat_v)
        right_v = normalize(cross(up_v, dir))
        up_v  = normalize(cross(dir, right_v))
        rotation = rotate_cam(theta_v, right_v, Vec3f0(0, 0, 1), dir)
        r_eyepos = lookat_v + rotation * (eyepos_v - lookat_v)
        r_up = normalize(rotation * up_v)
        cam[EyePosition] = r_eyepos
        cam[UpVector] = r_up
        return
    end
end

function add!(cam::PerspectiveCamera, ::Type{ProjectionView})
    on(cam, Area, Fov, Near, ProjectionType, LookAt, EyePosition, UpVector) do area, fov, near, projectiontype, lookatv, eyeposition, upvector
        zoom = norm(lookatv - eyeposition)
        # TODO this means you can't set FarClip... SAD!
        far = max(zoom * 5f0, 30f0)
        proj = projection_switch(area, fov, near, far, projectiontype, zoom)
        view = lookat(eyeposition, lookatv, upvector)
        cam[Projection] = proj
        cam[View] = view
        cam[ProjectionView] = proj * view
    end
end


function projection_switch{T <: Real}(
        wh::SimpleRectangle,
        fov::T, near::T, far::T,
        projection::ProjectionEnum, zoom::T
    )
    aspect = T(wh.w / wh.h)
    h = T(tan(fov / 360.0 * pi) * near)
    w = T(h * aspect)
    projection == Perspective && return frustum(-w, w, -h, h, near, far)
    h, w = h * zoom, w * zoom
    orthographicprojection(-w, w, -h, h, near, far)
end

function rotate_cam{T}(
        theta::Vec{3, T},
        cam_right::Vec{3, T}, cam_up::Vec{3, T}, cam_dir::Vec{3, T}
    )
    rotation = one(Q.Quaternion{T})
    # first the rotation around up axis, since the other rotation should be relative to that rotation
    if theta[1] != 0
        rotation *= Q.qrotation(cam_up, theta[1])
    end
    # then right rotation
    if theta[2] != 0
        rotation *= Q.qrotation(cam_right, theta[2])
    end
    # last rotation around camera axis
    if theta[3] != 0
        rotation *= Q.qrotation(cam_dir, theta[3])
    end
    rotation
end

wscale(screenrect, viewrect) = widths(viewrect) ./ widths(screenrect)

function update_cam!(cam::AbstractCamera, area)
    x, y = minimum(area)
    w, h = widths(area) ./ 2f0
    cam[Area] = FRect(area)
    cam[Projection] = orthographicprojection(-w, w, -h, h, -10_000f0, 10_000f0)
    cam[View] = translationmatrix(Vec3f0(-x - w, -y - h, 0))
    return
end



function add!(cam::AbstractCamera, window, ::Type{Pan})
    @needs window: Mouse.Drag
    on(window, Mouse.Drag, Base.RefValue(Vec(0.0, 0.0))) do dragging, startpos
        mp = Vec(window[Mouse.Position])
        if dragging == Mouse.down
            startpos[] = mp
        elseif dragging == Mouse.pressed && ispressed(window, Mouse.middle)
            diff = startpos[] .- mp
            startpos[] = mp
            a = cam[Area]
            st = diff .* wscale(window[Area], a)
            update_cam!(cam, FRect(minimum(a) .+ st, widths(a)))
        end
        return
    end
end
@field Zoom
function add!(cam::AbstractCamera, window, ::Type{Zoom})
    @needs window: Mouse.Scroll, Mouse.Position
    on(window, Mouse.Scroll) do x
        zoom = Float32(x[2])
        if zoom != 0
            a = cam[Area]
            z = 1 + (zoom * 0.10)
            mp = window[Mouse.Position]
            mp = (mp .* wscale(window[Area], a)) + minimum(a)
            p1, p2 = minimum(a), maximum(a)
            p1, p2 = p1 - mp, p2 - mp # translate to mouse position
            p1, p2 = z * p1, z * p2
            p1, p2 = p1 + mp, p2 + mp
            update_cam!(cam, FRect(p1, p2 - p1))
            z
        end
    end
end

function reset!(cam::AbstractCamera, boundingbox, preserveratio = true)
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
    return
end

function selection_rect(
        canvas,
        key = Mouse.left,
        button = Set([Keyboard.left_control, Keyboard.space])
    )
    @needs canvas: (Mouse.Drag, Mouse.Position)
    rect = FRect(0, 0, 0, 0)
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
                rect_vis[Primitive] = FRect(min, wh)
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

lerp{T}(a::T, b::T, val::AbstractFloat) = (a .+ (val * (b .- a)))

function add_restriction!(cam::AbstractCamera, window, rarea::SimpleRectangle, minwidths::Vec)
    area_ref = Base.RefValue(cam[Area])
    restrict_action = paused_action(1.0) do t
        o = lerp(origin(area_ref[]), origin(cam[Area]), t)
        wh = lerp(widths(area_ref[]), widths(cam[Area]), t)
        update_cam!(cam, FRect(o, wh))
    end
    on(window, Mouse.Drag) do drag
        if drag == Mouse.up && !isplaying(restrict_action)
            area = cam[Area]
            o = origin(area)
            maxi = maximum(area)
            newo = max.(o, origin(rarea))
            newmax = min.(maxi, maximum(rarea))
            maxi = maxi - newmax
            newo = newo - maxi
            newwh = newmax - newo
            scale = 1f0
            for (w1, w2) in zip(minwidths, newwh)
                stmp = w1 > w2 ? w1 / w2 : 1f0
                scale = max(scale, stmp)
            end
            newwh = newwh * scale
            area_ref[] = FRect(newo, newwh)
            if area_ref[] != cam[Area]
                play!(restrict_action)
            end
        end
        return
    end
    restrict_action
end
