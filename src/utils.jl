
# These should be moved to GeometryTypes, once figured out the future of Meshes
function uvmesh(prim::GeometryPrimitive, resolution = (2, 2))
    uv = decompose(UV{Float32}, prim, resolution)
    positions = decompose(Point2f0, prim, resolution)
    faces = decompose(GLTriangle, prim, resolution)
    vertices = map(identity, zip(positions, uv))
    view(vertices, faces)
end
function normalmesh(prim)
    V = GeometryTypes.vertices(prim)
    N = GeometryTypes.normals(prim)
    F = decompose(GLTriangle, prim)
    verts = map((a, b)-> (a, b), V, N)
    Base.view(verts, F)
end
