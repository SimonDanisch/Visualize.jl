using GeometryTypes, Visualize, FileIO
using ModernGL, StaticArrays
using GLAbstraction, GLWindow, ModernGL, GeometryTypes
using GLAbstraction: compile_shader

type VertexArray{T}
    id::GLuint
    length::Int
    indices::T
    context::GLAbstraction.GLContext
    function VertexArray{T}(id, bufferlength, indices::T)
        new(id, bufferlength, indices, GLAbstraction.current_context())
    end
end
function normalmesh(prim)
    V = GeometryTypes.vertices(prim)
    N = GeometryTypes.normals(prim)
    F = decompose(GLTriangle, prim)
    verts = map((a, b)-> (a, b), V, N)
    Base.view(verts, F)
end

function VertexArray(buffer::AbstractArray, attrib_location = 0)
    VertexArray(GLBuffer(buffer), -1, attrib_location)
end

function VertexArray{T, AT <: AbstractArray, IT <: AbstractArray}(
        view::SubArray{T, 1, AT, Tuple{IT}, false}, attrib_location = 0
    )
    indexes = view.indexes[1]
    buffer = view.parent
    VertexArray(GLBuffer(buffer), indexbuffer(indexes), attrib_location)
end

is_struct{T}(::Type{T}) = !(sizeof(T) != 0 && nfields(T) == 0)
is_glsl_primitive{T <: StaticVector}(::Type{T}) = true
is_glsl_primitive{T <: Union{Float32, Int32}}(::Type{T}) = true
is_glsl_primitive(T) = false

function VertexArray{T}(buffer::GLBuffer{T}, indices, attrib_location)
    id = glGenVertexArrays()
    glBindVertexArray(id)
    if isa(indices, GLBuffer)
        GLAbstraction.bind(indices)
    elseif !isa(indices, Integer)
        error("indexbuffer must be int or GLBuffer")
    end
    GLAbstraction.bind(buffer)
    if !is_glsl_primitive(T)
        for i = 1:nfields(T)
            FT = fieldtype(T, i); ET = eltype(FT)
            glVertexAttribPointer(
                attrib_location,
                GLAbstraction.cardinality(FT), GLAbstraction.julia2glenum(ET),
                GL_FALSE, sizeof(T), Ptr{Void}(fieldoffset(T, i))
            )
            glEnableVertexAttribArray(attrib_location)
            attrib_location += 1
        end
    else
        FT = T; ET = eltype(FT)
        glVertexAttribPointer(
            attrib_location,
            GLAbstraction.cardinality(FT), GLAbstraction.julia2glenum(ET),
            GL_FALSE, 0, C_NULL
        )
        glEnableVertexAttribArray(attrib_location)
    end
    glBindVertexArray(0)
    obj = VertexArray{typeof(indices)}(id, length(buffer), indices)
    #finalizer(obj, GLAbstraction.free)
    obj
end

function compile_program(shaders...)
    program = GLAbstraction.createprogram()
    glUseProgram(program)
    #attach new ones
    foreach(shaders) do shader
        glAttachShader(program, shader.id)
    end
    #link program
    glLinkProgram(program)
    if !GLAbstraction.islinked(program)
        error(
            "program $program not linked. Error in: \n",
            join(map(x-> string(x.name), shaders), " or "), "\n", GLAbstraction.getinfolog(program)
        )
    end
    program
end


vert = """
#version 450
layout (location = 0) in vec3 position;

void main(){
    gl_Position = vec4(position,  1.0);
}
"""

frag = """
#version 450
layout (location = 0) out vec4 frag_color;

void main(){
    frag_color = vec4(0,0,0, 1.0);
}
"""

isdefined(:window) && window.handle != C_NULL && GLFW.DestroyWindow(window)
window = create_glcontext(major = 4, minor = 2, debugging = true)
vertshader = compile_shader(Vector{UInt8}(vert), GL_VERTEX_SHADER, :vertexshader)
fragshader = compile_shader(Vector{UInt8}(frag), GL_FRAGMENT_SHADER, :fragshader)

program = compile_program(vertshader, fragshader)

objmesh = load(Pkg.dir("GLVisualize", "assets", "cat.obj"))
nmesh = normalmesh(objmesh)
vbo = VertexArray(nmesh)

glUseProgram(program)
glBindVertexArray(vbo.id)
glEnable(GL_DEPTH_TEST)
glClearColor(1, 1, 1, 1)
@async begin
    while isopen(window)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glDrawElements(
            GL_TRIANGLES,
            length(vbo.indices) * GLAbstraction.cardinality(vbo.indices),
            GLAbstraction.julia2glenum(eltype(vbo.indices)), C_NULL
        )
        GLWindow.swapbuffers(window)
        GLWindow.poll_glfw()
        yield()
    end
    GLFW.DestroyWindow(window)
    window.handle = C_NULL
end
