using Compat, GLWindow
@compat abstract type WindowEvent <: Field end

module Mouse
    using FieldTraits
    using FieldTraits: @field
    import Main: WindowEvent
    @enum Button left = 0 middle = 2 right = 1 # Be GLFW conform
    @enum DragEnum down up pressed notpressed

    @field Drag <: WindowEvent = Mouse.notpressed
    @field Position <: WindowEvent = (0, 0)
    @field Inside <: WindowEvent = false
    @field Buttons <: WindowEvent = Set(Mouse.Button[])
    @field Scroll <: WindowEvent = (0, 0)
end


@field Window = GLWindow.create_glcontext()
@field WindowOpen <: WindowEvent = false
@field WindowSize <: WindowEvent = (0, 0)
@field WindowPosition <: WindowEvent = (0, 0)
@field EnteredWindow <: WindowEvent = false
@field HasFocus <: WindowEvent = false
@field KeyboardButtons <: WindowEvent = Set(Int[])
@field UnicodeInput <: WindowEvent = Nullable{Char}()

@field DroppedFiles <: WindowEvent = String[]

# Complex events

@field Mouse2Object <: WindowEvent = nothing


@reactivecomposed type WindowEvents
    Window
    WindowOpen
    WindowSize
    WindowPosition
    EnteredWindow
    HasFocus

    Mouse.Inside
    Mouse.Buttons
    Mouse.Position
    Mouse.Scroll
    Mouse.Drag

    KeyboardButtons
    UnicodeInput

    DroppedFiles
    # Complex events
    # Mouse2Object
end
#
# # Window Events are global to the window
# global const isregistered = WindowEvents(
#     ntuple(x-> false, nfields(WindowEvents))...
# )
#
# function on(
#         f, ::Type{MouseDrag}, composed::Composable,
#         args...; start_condition = true
#     )
#     dragging = false; startposition = composed[MousePosition];
#     on(MousePosition, composed) do mp
#         mousebutton = composed[MouseButon]
#         if mousebutton == :down && !dragging && start_condition
#             startposition = mp
#             f(false, startposition, mp, args...) # just started, so dragging is still false
#         elseif mousebutton == :down && dragging
#             f(true, startposition, mp, args...)
#         else
#             dragging = false
#         end
#     end
# end
# function register_callback(::Type{LeftClick}, composed::Composable)
# end
# function register_callback(::Type{MiddleClick}, composed::Composable)
# end
# function register_callback(::Type{Mouse2Object}, composed::Composable)
# end
#
# function register_callback{Field <: WindowEvent}(::Type{Field}, composed::Composable)
#     if !isregistered[Field]
#         currentbackend().windowcallbacks[Field](
#             composed[Window], composed
#         )
#         isregistered[Field] = true
#     end
# end
# function on{Field <: WindowEvent}(f, ::Type{Field}, composed::Composable, args...)
#     register_callback(Field, composed)
#     links = composed[Links]
#     if haskey(links, field)
#         # adds a callback to the field
#         push!(links[field], (f, args))
#     end
# end
