include("rasterizer.jl")
function uvmesh(prim::GeometryPrimitive, resolution = (2, 2))
    uv = decompose(GeometryTypes.UV{Float32}, prim, resolution)
    positions = decompose(Point2f0, prim, resolution)
    faces = decompose(GLTriangle, prim, resolution)
    vertices = map(identity, zip(positions, uv))
    Base.view(vertices, faces)
end

function vertex_shader(vertex, args)
    p, uv = vertex
    proj = args[1]
    position = proj * Vec{4, eltype(p)}(p[1], p[2], 0f0, 1f0)
    position, (uv,)
end
function fragment_shader(fragment_in, args)
    uv, = fragment_in
    image = args[2]
    color = image[uv]
    (color,)
end
framebuffer = zeros(RGB{Float32}, 500, 500)
depthbuffer = ones(Float32, size(framebuffer))

proj = orthographicprojection(SimpleRectangle(0, 0, 500, 500), -10_000f0, 10_000f0)
rect = SimpleRectangle(20, 20, 300, 300)
mesh = uvmesh(rect)
image = Sampler(load(homedir()*"/Desktop/matcha.png"))
rasterize!(depthbuffer, (framebuffer,), mesh, (proj, image), vertex_shader, fragment_shader)
save("test.png", framebuffer)
