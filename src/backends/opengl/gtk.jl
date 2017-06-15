using Gtk
using Gtk.GConstants

@field GtkParent = Gtk.Window("")

@composed type GtkWindow <: AbstractGLWindow
    <: GLWindow
    GtkParent
end

function default(::Type{GtkParent}, data::Partial{GtkWindow})
    area = get!(data, Area)
    resolution = round.(Int, widths(get(data, Area)))
    parent = Gtk.Window(string(get(data, Name)), resolution..., true, true)
    Gtk.visible(parent, get(data, Visible))
    Gtk.setproperty!(parent, Symbol("is-focus"), get(data, Focused))
    parent
end

function default(::Type{NativeWindow}, data::Partial{GtkWindow})
    parent = get!(data, GtkParent)
    window = Gtk.GLArea()
    opengl_version = get!(data, OpenGLVersion)
    Gtk.gl_area_set_required_version(window, opengl_version.major, opengl_version.minor)
    GLAbstraction.new_context(window)
    push!(parent, window)
    window
end

function add!(window::GtkWindow, ::Type{Area})
    function callback_w(widget::Gtk.GtkGLArea, width::Int32, height::Int32)
        rect = window[Area]
        window[Area] = IRect(minimum(rect), width, height)
        return true
    end
    signal_connect(callback_w, window[Window], "Scroll")
    add_events(window[Window], GConstants.GdkEventMask.SCROLL)
    return
end

function add!(window::GtkWindow, ::Type{Mouse.Scroll})
    function callback(widget::Gtk.GtkGLArea, s::Gtk.GdkEventScroll)
        window[Scroll] = (s.x, s.y)
        return true
    end
    signal_connect(callback, window[NativeWindow], "scroll-event")
    add_events(window[NativeWindow], GConstants.GdkEventMask.SCROLL)
    return
end

function add!(window::GtkWindow, ::Type{Mouse.Position})
    function callback(widget::Gtk.GtkGLArea, s::Gtk.GdkEventMotion)
        window[Mouse.Position] = (s.x, s.y)
        return true
    end
    add_events(window[NativeWindow], GConstants.GdkEventMask.POINTER_MOTION)
    signal_connect(callback, window[NativeWindow], "motion-notify-event")
    return true
end

function to_mouse_button(x)
    if x == 1
        Mouse.left
    elseif x == 2
        Mouse.middle
    elseif x == 3
        Mouse.right
    else
        # TODO turn into error
        warn("Button is $x, while $(Gtk.GdkModifierType.BUTTON1)")
        Mouse.left
    end
end
function add!(window::GtkWindow, ::Type{Mouse.Buttons})
    function callback(widget::Gtk.GtkGLArea, event::Gtk.GdkEventButton)
        button = to_mouse_button(event.button)
        action = event.event_type
        set = window[Mouse.Buttons]
        if action in (GdkEventType.BUTTON_PRESS:GdkEventType.TRIPLE_BUTTON_PRESS)
            push!(set, button)
        elseif action == GdkEventType.BUTTON_RELEASE
            delete!(set, button)
        else
            warn("unknown action: $(action)")
        end
        window[Mouse.Buttons] = set # trigger setfield event!
        return true
    end
    add_events(window[NativeWindow],
        GConstants.GdkEventMask.GDK_BUTTON_PRESS_MASK |
        GConstants.GdkEventMask.GDK_BUTTON_RELEASE_MASK
    )
    signal_connect(callback, window[NativeWindow], "button_press_event")
    signal_connect(callback, window[NativeWindow], "button_release_event")
    return
end
# gint glarea_key_press_event(GtkWidget *widget, GdkEventKey *event)
# {
#   switch (event->keyval) {
#     case GDK_r:
#       g_print("Button r pressed...redrawing\n");
#       gtk_widget_draw(glarea, (GdkRectangle *)NULL);
#       break;
#     case GDK_l:
#       g_print("Button l pressed...redrawing\n");
#       gtk_widget_draw(glarea, (GdkRectangle *)NULL);
#       break;
#     case GDK_p:
#       g_print("Button p pressed...redrawing\n");
#       gtk_widget_draw(glarea, (GdkRectangle *)NULL);
#       break;
#   }
#   return (TRUE);
# }


function make_context_current(x::Gtk.GLArea)
    Gtk.make_current(x)
    GLAbstraction.make_context_current(x)
end

function gtk_render(gl_area, gdk_context)
    signal_connect(gtk_render, area, "render")
    global draw_cat, uniforms, args, vbo
    glEnable(GL_DEPTH_TEST)
    glDepthMask(GL_TRUE)
    glDepthFunc(GL_LEQUAL)
    glDisable(GL_CULL_FACE)
    GLAbstraction.enabletransparency()
    glClearColor(1,1,1,1)
    glViewport(0, 0, 200, 200)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    args = (Vec3f0(1, 0, 0), cam[Visualize.Projection], cam[View])
    uniforms[3][1] = args # update
    draw_cat(vbo, uniforms)
    glFlush()
    return false
end
