# Visualize

[![Build Status](https://travis-ci.org/SimonDanisch/Visualize.jl.svg?branch=master)](https://travis-ci.org/SimonDanisch/Visualize.jl)

[![Coverage Status](https://coveralls.io/repos/SimonDanisch/Visualize.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/SimonDanisch/Visualize.jl?branch=master)

[![codecov.io](http://codecov.io/github/SimonDanisch/Visualize.jl/coverage.svg?branch=master)](http://codecov.io/github/SimonDanisch/Visualize.jl?branch=master)


# API design

Visualize will heavily rely on [FieldTraits](https://github.com/SimonDanisch/FieldTraits.jl).
It solves a couple of problems.
First of all, visualization code is full of attributes which carry around semantic
but might change behavior depending on the context.
We solve this by having a composed type, which fields are addressed with singleton types or other composed types.
This solves the following problems:

# Problem 1: Conversions and documentation
I want to fully leverage Julia's ability to allow users to define custom types for any attributes.
But since the graphics backend needs to handle any combination of attribute and user types,
this was resulting in a conversion and documentation nightmare.

This problem explodes, when introducing different backends, which have essentially the same user facing behavior.

Let me illustrate how FieldTraits solves this with a very simple example:
```Julia
using FieldTraits
# define a field
@field Color

# first of all, we can define an "abstract" documentation for a Color field
"""
Color attribute, accepts any kind of Colors.Colorant!
"""
Color

# @composed is how you define a type from FieldTraits
@composed Surface
    # If behavior changes in a certain context we we can overwrite the documentation:
    """
    Color can be Vector{Colorant} or Colorant
    """
    Color
    #... other fields/attributes we don't care about right now
end
@composed Polygon
    # doesn't need to overwrite documentation since it's agrees with the basic documentation!
    Color
    #...
end

# now we want to allow only solid colors for Polygon, and colormaps + solid colors for Surfaces
function Base.convert(parent::Type{Surface}, field::Type{Color}, value)
    isa(value, Vector{Colorant}) || isa(value, Colorant) && return value
    throw(UsageError(parent, field, value)) # throws an error with the correct usage documentation
end
function Base.convert(parent::Type{Polygon}, field::Type{Color}, value)
    isa(value, Colorant) && return value
    throw(UsageError(parent, field, value))
end
```

This pattern becomes even more powerful when different backends are involved!
Most field semantics and documentations are shared, but we might need to
convert to slightly different types to work with the backend:
```
@composed Image
    ImageData
    #other fields...
end
abstract type GLVisualizable <: Composable end
@composed GLImage <: GLVisualizable
    ImageData::Texture # simple converts to a known type can be defined with a type assert
    <: Image # inherit all fields from Image, but ImageData will be overloaded!
    # So the rest of the behavior stays the same, even the documentation and behavior of ImageData will  
    #  just get converted to a different target type in the end.
end
# now we can also just create a catchall conversion for any GLVisualizable:
function Base.convert{T <: GLVisualizable, F <: Field}(::Type{T}, ::Type{F}, value)
     # GLAbstraction already have an automatic conversion function, which converts e.g. Float64 to Float32
     # and Arrays to buffers and so forth
    GLAbstraction.gl_convert(value)
end
```

Another great advantage we get is, that composed types are fully typed and getindex/setindex is type stable.
This is crucial, since we want to use them directly in the e.g. OpenGL rendering code.
So we can feed an opengl shader directly with an e.g. `GLImage`, and because of the type
stability we can fully unrole the rendering code leading to great performance!

# Problem 2: default generation

Graphics are 90% about generating sensible defaults, since most visualization types
have lots of attributes while the user usually only cares about customizing 10% of them.

What we can do with FieldTraits for defaults is essentially the same as for conversions.
You can define defaults for a field, which can be overloaded for different parents.
Let's see how this would look for our previous example:
```Julia
# First of all, we could have defined the Color field like this, to already
# include a default value
@field Color = RGB(1, 0, 0)

# than we can overwrite it for the surface to default to a colormap
# note that we don't need that for Polygon, since a sensible default is already defined.
function default(::Type{Surface}, ::Field{Color})
    Colors.colormap("Blues")
end

# What we sometimes need though, which isn't covered by this, is to generate defaults from
# an incomplete set of user input. We solve this by overloading default:

function FieldTraits.default{(::Type{Image}, ::Field{Ranges}, incomplete)
    # asserts that incomplete at least contains ImageData, assigns it to image or throws an appropriate error
    @needs incomplete: image = ImageData
    # not the best example, but lets say we want to figure out how much space the image should take when we display it
    # I started calling that ranges, since it assigns a range to every dimension. This is pretty much a boundingbox
    (1:size(image, 1), 1:size(image, 2))
end
```

We use tuples of pairs to have allow the user to define statically inferable incomplete sets of attributes:
and it will end up in the `default` function as the `incomplete` argument:
```Julia
image = Image((ImageData => load("test.jpg"), ))
```
Now we might want to write backend independent visualization code, but still need to convert to backend specific types
when displaying with a certain backend.
FieldTraits defines conversions for `GLImage(image::Image)` for that purpose,
which will fill in defaults that are only needed by the OpenGL backend, do the proper conversion
and ignores fields that the OpenGL backend isn't able to use!

# Problem 3: Styling

What if we want to consistently style our visualizations?
The simplest approach can look something like this:

```Julia
@composed MySurface
    <: Surface
end
default(::Type{MySurface}, ::Field{Color}) = Colors.colormap("Reds")
```

now we have a Surface type that will default to a red colormap.
Admittedly this kind of styling approach is not very scalable.
What we rather want here is to take attributes from a template which might look like this:

```Julia
@composed MyTheme
    Color = RGB(0, 0, 1)
    ...
end
Theme = MyTheme()
Surface(Theme, (Data => rand(10, 10), Bla => ...))
```
Now, the all attributes that are not in the incomplete attributes from the user will be taken from the theme!
We still need to figure out a nice way to give a surface a colormap default for the Color field in this example.
Maybe something like this will be workable:
```Julia
@composed MyTheme
    Color = RGB(0,0,1)
    (Surface => Color) => colormap("Reds")
end
```

# Problem 4: Events

I will write more about this later.
But you can already take a look at [events.jl](https://github.com/SimonDanisch/Visualize.jl/blob/master/src/events.jl)
To get a feel for the API.
One of the main features is to register to `setindex!`` of a field, which will look like this:
```Julia
@composed WindowEvents
    Mouse.Position
end
@composed Canvas
    <: WindowEvents
end
canvas = Canvas()
add!(canvas, Mouse.Position)

# add's the current mouse position event callback
# This will be over-loadable by different backends.
# so if the Canvas is created with a GLFW window, it will register a mouse position
# callback with GLFW. If its created from a WebGL canvas, it will get the event from JavaScript

# Now every time the mouse position callbacks updates mouse position in Canvas we can do something:
FieldTraits.on(canvas, Mouse.Position) do mouse
    println(mouse)
    return
end
```

# Higher level api

This will still need some more thinking, but I might aime for something inspired by [Vega-Lite](https://vega.github.io/vega-lite/).
It will fit nicely with `FieldTraits`, since Fields can also be composite types which allows for nested visualization definition.
So you could do something like:

```Julia
canvas = Canvas(
    Area => (500mm, 500mm)
)
vis = (
    Canvas => canvas,
    Surface => (
        Data => rand(40, 40),
        Color => colormap("Reds")
    )
    Volume => (
        ...
    )
)
on(canvas, Mouse.Position) do mousepos
    vis[Surface][Color] = ...# update some value in vis
end
```
