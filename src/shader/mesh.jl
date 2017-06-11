function vert_mesh(vertex::VertexN, light, shading, args)
    #args = (solid_color, proj, view)
    proj = args[2]
    viewmodel = args[3]

    pos = vertex.position
    position_camspace = viewmodel * Vec4f0(pos[1], pos[2], pos[3],  1f0)
    # direction to light
    lightdir = normalize(light.position .- pos)
    # direction to camera
    # screen space coordinates of the vertex
    pos_screen = proj * position_camspace
    v2frag = Vert2Frag(-position_camspace[Vec(1,2,3)], vertex.normal, lightdir)
    pos_screen, v2frag
end

function frag_mesh(vertex_out::Vert2Frag, light, shading, args)
    # (solid_color, proj, view)
    solid_color = args[1]
    V = vertex_out.position
    L = normalize(vertex_out.lightdir)
    N = normalize(vertex_out.normal)
    c = blinnphong(V, N, L, solid_color, shading, light)
    (Vec4f0(c[1], c[2], c[3], 1f0),)
end
