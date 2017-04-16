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
    _setindex!(ct, value, field)
    links = ct[Links]
    if haskey(links, field)
        link = links[field]
        for (func, fields, args) in link
            func(map(f-> ct[f], fields)..., args...)
        end
    end
    value
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

function on(F, object::ReactiveComposable, head, tail...)
    links = object[Links]
    args = (head, tail...)
    _fields = []
    field, state = first(args), start(args)
    while field <: Field # find the first n fields
        push!(_fields, field)
        field, state = next(args, state)
    end
    fields = (_fields...,)
    for field in fields
        if haskey(links, field)
            # adds a callback to the field
            push!(links[field], (F, fields, args))
        end
    end
end
