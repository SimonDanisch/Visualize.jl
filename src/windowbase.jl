@compat abstract type WindowEvent <: Field end

module Mouse
    using FieldTraits
    using FieldTraits: @field
    import ..Visualize: WindowEvent

    @enum Button left = 0 middle = 2 right = 1 # Be GLFW conform
    @enum DragEnum down up pressed notpressed

    @field Drag <: WindowEvent = notpressed
    @field Position <: WindowEvent = (0.0, 0.0)
    @field Inside <: WindowEvent = false
    @field Buttons <: WindowEvent = Set(Button[])
    @field Scroll <: WindowEvent = (0.0, 0.0)
end

include("keyboard.jl")

@field Window

function default(parent, ::Type{Window})
    GLWindow.create_glcontext()
end

@field WindowOpen <: WindowEvent = false
@field WindowSize <: WindowEvent = (0, 0)
@field WindowPosition <: WindowEvent = (0, 0)
@field EnteredWindow <: WindowEvent = false
@field HasFocus <: WindowEvent = false
@field DroppedFiles <: WindowEvent = String[]

# Complex events

@field Mouse2Object <: WindowEvent = nothing


@reactivecomposed type WindowEvents
    Window
    Area
    WindowOpen
    EnteredWindow
    HasFocus

    Mouse.Inside
    Mouse.Buttons
    Mouse.Position
    Mouse.Scroll
    Mouse.Drag

    Keyboard.Buttons
    Keyboard.Unicode

    DroppedFiles
    # Complex events
    # Mouse2Object
end

@reactivecomposed type Camera
    Area
    Projection
    View
    ProjectionView
end
@composed type Canvas <: ReactiveComposable
    <: Shared
    <: WindowEvents
    Spacetransform
end

#
# # Window Events are global to the window
# global const isregistered = WindowEvents(
#     ntuple(x-> false, nfields(WindowEvents))...
# )

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
