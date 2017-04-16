using FieldTraits
using FieldTraits: @reactivecomposed, @field, Field, UsageError, @needs, Composable
import FieldTraits: on, Fields, Links

include("windowbase.jl")
@field Projection
@field View
Fields(WindowEvents)

@reactivecomposed type Camera
    View
    Projection
end

composed = WindowEvents()


function add!(events, ::Type{Mouse.Position})
    @needs events: window = Window
    window = events[Window]
    GLFW.SetCursorPosCallback(window, (window, x, y) -> begin
        events[Mouse.Position] = (x, y)
    end)
    return
end
using MacroTools

function add!(events, ::Type{Mouse.Buttons})
    @needs events: window = Window
    GLFW.SetMouseButtonCallback(window, (window, button, action, mods) -> begin
        set = events[Mouse.Buttons]
        button_enum = Mouse.Button(button)
        if button != GLFW.KEY_UNKNOWN
            if action == GLFW.PRESS
                push!(set, button_enum)
            elseif action == GLFW.RELEASE
                delete!(set, button_enum)
            elseif action == GLFW.REPEAT
                # nothing needs to be done, besides returning the same set of keys
            else
                error("Unrecognized enum value for GLFW button press action: $action")
            end
        end
        events[Mouse.Buttons] = set # trigger setfield event!
    end)
    return
end
function add!(events::Composable, ::Type{Mouse.Drag})
    @needs events: Mouse.Buttons, Mouse.Position, Mouse.Drag

    local indrag::Bool = false;
    local tracked_mousebutton::Mouse.Button = Mouse.left

    on(events, Mouse.Position, Mouse.Buttons) do mp, buttons
        # only track if still the same button is pressed
        if length(buttons) == 1 &&
                (!indrag || tracked_mousebutton == first(buttons))
            if !indrag
                indrag = true
                events[Mouse.Drag] = Mouse.down # just started, so dragging is still false
                return
            elseif indrag
                events[Mouse.Drag] = Mouse.pressed
                return
            end
        end
        # already on notpressed, no need for update
        if events[Mouse.Drag] != Mouse.notpressed
            events[Mouse.Drag] = indrag ? Mouse.up : Mouse.notpressed
        end
        indrag = false
        return
    end
end


using GLWindow
events = WindowEvents()
add!(events, Mouse.Position)
add!(events, Mouse.Buttons)
add!(events, Mouse.Drag)

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
# GLFW.SetMouseButtonCallback(w, nothing)
# empty!(events[FieldTraits.Links][Mouse.Position])
# empty!(events[FieldTraits.Links][Mouse.Drag])
on(println, events, Mouse.Drag)
