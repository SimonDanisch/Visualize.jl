emit_placeholder(position, fragout) = nothing

glsl_type{T <: AbstractFloat}(::Type{T}) = Float32
glsl_type{T}(::UniformBuffer{T}) = T
glsl_type{T, N}(::Texture{T, N}) = gli.GLTexture{glsl_type(T), N}

immutable GLRasterizer{Vertex, N, Args}
    program::GLuint
    uniform_locations::NTuple{N, Int}
end

function (p::GLRasterizer{Vertex, N, Args}){Vertex, N, Args}(vertexarray::VertexArray{Vertex}, uniforms::Args)
    glUseProgram(p.program)
    glBindVertexArray(vertexarray.id)
    for (i, uniform_idx) in enumerate(p.uniform_locations)
        uniform = uniforms[i]
        blockid = i - 1
        if !isa(uniform, Texture)
            glUniformBlockBinding(p.program, uniform_idx, blockid)
            glBindBufferBase(GL_UNIFORM_BUFFER, blockid, uniforms[i].buffer.id)
        else
            GLAbstraction.gluniform(uniform_idx, blockid, uniform)
        end
    end
    draw_vbo(vertexarray)
    glBindVertexArray(0)
end

function GLRasterizer{T <: Tuple}(
        vertexarray, uniforms::T,
        vertex_main, fragment_main;
        # geometry shader is optional, so it's supplied via kw_args
        geometry_main = nothing,
        max_primitives = 4,
        primitive_in = :points,
        primitive_out = :triangle_strip
    )
    shaders = Shader[]

    uniform_types = map(glsl_type, uniforms)
    vertex_type = eltype(vertexarray)

    argtypes = (vertex_type, uniform_types...)
    vsource, vertexout = emit_vertex_shader(vertex_main, argtypes)
    vshader = compile_shader(vsource, GL_VERTEX_SHADER, :particle_vert)
    write(STDOUT, vsource)
    push!(shaders, vshader)
    fragment_in = vertexout # we first assume vertex stage outputs to fragment stage
    if geometry_main != nothing
        argtypes = (typeof(emit_placeholder), vertexout, uniform_types...)
        gsource, geomout = emit_geometry_shader(
            geometry_main, argtypes,
            max_primitives = max_primitives,
            primitive_in = primitive_in,
            primitive_out = primitive_out
        )
        write(STDOUT, gsource)
        gshader = compile_shader(gsource, GL_GEOMETRY_SHADER, :particle_geom)
        push!(shaders, gshader)
        fragment_in = geomout # rewire if geometry shader is present
    end

    argtypes = (fragment_in, uniform_types...)
    fsource, fragout = emit_fragment_shader(fragment_main, argtypes)
    fshader = compile_shader(fsource, GL_FRAGMENT_SHADER, :particle_frag)
    push!(shaders, fshader)
    write(STDOUT, fsource)
    program = compile_program(shaders...)
    N = length(uniform_types)
    uniform_locations = ntuple(N) do i
        if isa(uniforms[i], Texture)
            GLAbstraction.get_uniform_location(program, "image")
        else
            glGetUniformBlockIndex(program, glsl_gensym("UniformArg$i"))
        end
    end
    GLRasterizer{vertex_type, N, T}(
        program, uniform_locations
    )
end

export GLRasterizer
