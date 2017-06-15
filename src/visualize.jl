
function visualize(window::AbstractWindow, primitive)
    drawable, args = Drawable(window, primitive)
    push!(window[Renderlist], primitive => (drawable, args))
    return drawable
end
