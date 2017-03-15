abstract ReactiveComposable <: Composable

@field Links begin
    Links = ComposedDict()
end

"""
Composable, that allows one to link fields and register callbacks to field changes
"""
macro reactivecomposed(expr)
    composed_type(expr, [Links], ReactiveComposable)
end

@propagate_inbounds function setindex!{F <: Field}(ct::ReactiveComposable, value, field::Type{F})
    links = ct[Links]
    if haskey(links, field)
        link = links[field]
        for (func, args) in link
            func(value, args...)
        end
    end
    _setindex!(ct, value, field)
end


"""
Links a field with another in to Composable types.
After this operation, setindex!(a, val) will result in
setindex!(b, val) being executed.
link!(Scale, a => b)
"""
function link!{F <: Field}(::Type{F}, pair::Pair{ReactiveComposable, Composable})
    a, b = pair
    on(F, a) do val
        b[F] = val
    end
end
function on(F, field::Field, object::ReactiveComposable, args...)
    links = object[Links]
    if haskey(links, field)
        # adds a callback to the field
        push!(links[field], (F, args))
    end
end
