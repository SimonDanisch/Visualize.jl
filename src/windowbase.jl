abstract WindowEvent <: Field

@field WindowOpen <: WindowEvent
@field WindowSize <: WindowEvent
@field WindowPosition <: WindowEvent
@field EnteredWindow <: WindowEvent
@field HasFocus <: WindowEvent

@field MouseInside <: WindowEvent
@field MouseButtons <: WindowEvent
@field MousePosition <: WindowEvent
@field Scroll <: WindowEvent

@field KeyboardButtons <: WindowEvent
@field UnicodeInput <: WindowEvent

@field DroppedFiles <: WindowEvent

# Complex events
@field MouseDrag <: WindowEvent
@field LeftClick <: WindowEvent
@field RightClick <: WindowEvent
@field MiddleClick <: WindowEvent
@field Mouse2Object <: WindowEvent


@composed type WindowEvents
    WindowOpen
    WindowSize
    WindowPosition
    EnteredWindow
    HasFocus

    MouseInside
    MouseButtons
    MousePosition
    Scroll

    KeyboardButtons
    UnicodeInput

    DroppedFiles

    # Complex events
    # MouseDrag
    # LeftClick
    # RightClick
    # MiddleClick
    # Mouse2Object
end

# Window Events are global to the window
global const isregistered = WindowEvents(
    ntuple(x-> false, nfields(WindowEvents))...
)

function on(
        f, ::Type{MouseDrag}, composed::Composable,
        args...; start_condition = true
    )
    dragging = false; startposition = composed[MousePosition];
    on(MousePosition, composed) do mp
        mousebutton = composed[MouseButon]
        if mousebutton == :down && !dragging && start_condition
            startposition = mp
            f(false, startposition, mp, args...) # just started, so dragging is still false
        elseif mousebutton == :down && dragging
            f(true, startposition, mp, args...)
        else
            dragging = false
        end
    end
end
function register_callback(::Type{LeftClick}, composed::Composable)
end
function register_callback(::Type{MiddleClick}, composed::Composable)
end
function register_callback(::Type{Mouse2Object}, composed::Composable)
end

function register_callback{Field <: WindowEvent}(::Type{Field}, composed::Composable)
    if !isregistered[Field]
        currentbackend().windowcallbacks[Field](
            composed[Window], composed
        )
        isregistered[Field] = true
    end
end
function on{Field <: WindowEvent}(f, ::Type{Field}, composed::Composable, args...)
    register_callback(Field, composed)
    links = composed[Links]
    if haskey(links, field)
        # adds a callback to the field
        push!(links[field], (f, args))
    end
end
