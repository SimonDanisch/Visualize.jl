@field ShadingFunction = blinnphong

@composed type MeshUniforms
    Model
    Color
    ShadingFunction
end


function vert_mesh(vertex::AbstractVertex, canvas, light, shading, uniforms)
    #args = (solid_color, proj, view)
    pos = to_vec4(getposition(vertex))
    mv = canvas.view * uniforms.model
    position_camspace = mv * pos
    # direction to light
    lightdir = normalize(light.position .- pos[Vec(1, 2, 3)])
    # direction to camera
    # screen space coordinates of the vertex
    pos_screen = canvas.projection * position_camspace
    return (
        pos_screen,
        Vert2Frag(
            getcolor(vertex, uniforms),
            -position_camspace[Vec(1,2,3)],
            getnormal(vertex),
            getuv(vertex),
            lightdir
        )
    )
end

function frag_mesh(vertex_out::Vert2Frag, canvas, light, shading, uniforms)
    # (solid_color, proj, view)
    color = vertex_out.color
    V = vertex_out.position
    L = normalize(vertex_out.lightdir)
    N = normalize(vertex_out.normal)

    c = uniforms.shadingfunction(V, N, L, color[Vec(1, 2, 3)], shading, light)
    (Vec4f0(c[1], c[2], c[3], color[4]),)
end
