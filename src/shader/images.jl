function vert_image(vertex, args)
    p, uv = vertex
    proj = args[1]
    position = proj * Vec{4, eltype(p)}(p[1], p[2], 0f0, 1f0)
    position, (uv,)
end
function frag_image(fragment_in, args)
    uv, = fragment_in
    image = args[2]
    color = image[uv]
    (color,)
end
