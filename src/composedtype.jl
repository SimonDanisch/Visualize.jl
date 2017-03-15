import Base: @propagate_inbounds, @pure, tail, haskey, getindex, setindex!

abstract Composable
const Field = Composable

"""
Calculates the index into a struct type from a Composable type.
E.g.
```
    @composed type Test
        Scale
        Position
    end
    fieldindex(Test, Position) == 2
```
"""
fieldindex{T <: Composable, F <: Field}(::Type{T}, ::Type{F}) = (Val{0}(),)
fieldindex{T <: Composable, F <: Field}(::T, ::Type{F}) = fieldindex(T, F)


function haskey{T <: Composable, F <: Field}(c::T, field::Tuple)
    haskey(c, field) > 0 && haskey(c, tail(field))
end
haskey{T <: Composable, N}(c::T, field::Val{N}) = N > 0
haskey{T <: Composable, N}(c::T, field::Tuple{Val{N}}) = N > 0

function haskey{T <: Composable, F <: Field}(c::T, field::Type{F})
    haskey(c, fieldindex(T, F))
end

"""
Returns the type of a field in a composed type.
Would like to extend Base.fieldtype, but that is an Builtin function which can't
be extended
"""
function cfieldtype(ct::Composable, field)
    typeof(getindex(ct, field))
end

"""
Converts a value to the field type of field in a composed type.
"""
function fieldconvert(ct::Composable, field, value)
    convert(cfieldtype(ct, field), value)
end
@propagate_inbounds function _setindex!{N}(ct::Composable, val, field::Val{N})
    setfield!(ct, N, fieldconvert(ct, field, val))
end
@propagate_inbounds function _setindex!{N}(ct::Composable, val, field::Tuple{Val{N}})
    setfield!(ct, N, fieldconvert(ct, field, val))
end
@propagate_inbounds function _setindex!(ct::Composable, val, field::Tuple)
    prim = ct[Base.front(field)]
    _setindex!(prim, val, last(field))
end
@propagate_inbounds function _setindex!{F <: Field}(ct::Composable, val, ::Type{F})
    _setindex!(ct, val, fieldindex(ct, F))
end
@propagate_inbounds function setindex!{F <: Field}(ct::Composable, value, field::Type{F})
    _setindex!(ct, value, field)
end
@propagate_inbounds function getindex{N}(ct::Composable, field::Val{N})
    getfield(ct, N)
end
@propagate_inbounds function getindex{N}(ct::Composable, field::Tuple{Val{N}})
    getfield(ct, N)
end
@propagate_inbounds function getindex(ct::Composable, field::Tuple)
    getindex(getindex(ct, first(field)), tail(field))
end
@propagate_inbounds function getindex{F <: Field}(ct::Composable, ::Type{F})
    getindex(ct, fieldindex(ct, F))
end

# Default Constructor, empty constructor
function (::Type{T}){T <: Composable}()
    fields = Fields(T)
    if isempty(fields) # we're at a leaf field without an empty constructor defined
        # TODO think of good error handling, that correctly advises the user
        error("No default for $T")
    end
    T(map(Field-> Field(), fields))
end

# Constructor from another Composable type
function (::Type{T}){T <: Composable}(c::Composable)
    fields = map(Fields(T)) do Field
        get(c, Field, Field)
    end
    T(fields)
end
# Decouple implementation of field from declaration by using a macro
macro field(x)
    esc(quote
        immutable $x <: Field end
        Fields(::Type{$x}) = ()
    end)
end


"""
Recursively adds fieldindex methods for composed types.
E.g.:
```
@composed Transform
    Scale
    Rotation
    Position
end
@composed Test
    Transform
end
Will result in Test having fieldindex methods also for Scale Rotation and position
```
"""
function add_fieldindex(Field, block, idx, name)
    push!(block.args,
        :(fieldindex{T <: $name}(::Type{T}, ::Type{$Field}) = $idx)
    )
    if Field <: Composable
        for (i, T) in enumerate(Fields(Field))
            newidx = Expr(:tuple, idx.args..., :(Val{$i}()))
            add_fieldindex(T, block, newidx, name)
        end
    end
end


function composed_type(expr, additionalfields = [], supertype = Composable)
    @assert expr.head == :type
    name = expr.args[2]
    idxfuncs = Expr(:block)
    parameters = []
    fields = []
    idx = 1
    composedfields = [additionalfields; expr.args[3].args]
    typedfields = map(composedfields) do field
        if isa(field, Symbol)
            Field = eval(field)
            # Recursively add fieldinex methods
            add_fieldindex(Field, idxfuncs, :((Val{$idx}(),)), name)
            push!(fields, field)
            idx += 1
            fname = Symbol(lowercase(string(field)))
            :($fname::$field)
        else
            field # line number
        end
    end

    fielfund = :(Fields(::Type{$name}) = ($(fields...),))
    typename, supertype = if isa(name, Symbol)
        name, supertype
    elseif isa(name, Expr) && name.head == :(<:)
        name.args
    end
    quote
        type $typename{$(fields...)} <: $supertype
            $(typedfields...)
        end
        $(esc(fielfund))
        $(esc(idxfuncs))
    end

end
"""
"""
macro composed(expr)
    composed_type(expr)
end

# A dictionary wrapper supporting the CmposedApi
immutable ComposedDict{K, V} <: Composable
    data::Dict{Symbol, V}
end

haskey(cd::ComposedDict, k) = haskey(cd.data, k)

function getindex(cd::ComposedDict, k)
    # TODO search!
    getindex(cd.data, Symbol(k))
end

function setindex!(cd::ComposedDict, val, k)
    # TODO search!
    setindex!(cd.data,val, Symbol(k))
end
