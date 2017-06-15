using GeometryTypes, Visualize, FileIO
using ModernGL, StaticArrays
using GLAbstraction, GLWindow, ModernGL, GeometryTypes
using GLAbstraction: compile_shader
using Visualize: Window, WindowEvents, Mouse, Keyboard, PerspectiveCamera, add!
using Visualize: Area, Projection, View, EyePosition, LookAt, UpVector, Translation
using Visualize: Rotation, ProjectionView, TranslationSpeed, RotationSpeed
import GLFW

function read_ifs(filename)
    open(filename) do io
        function str()
            n = read(io, UInt32)
            String(read(io, UInt8, n))
        end
        ifs = str()
        zero = read(io, Float32)
        name = str()
        vertices = str()
        nverts = read(io, UInt32)
        verts = Vector{Point3f0}(nverts)
        for i = 1:nverts
            verts[i] = Point3f0(
                read(io, Float32),
                read(io, Float32),
                read(io, Float32)
            )
        end
        tris = str()
        nfaces = read(io, UInt32)
        faces = Vector{GLTriangle}(nfaces)
        for i = 1:nfaces
            faces[i] = GLTriangle(
                read(io, UInt32) + UInt32(1),
                read(io, UInt32) + UInt32(1),
                read(io, UInt32) + UInt32(1)
            )
        end
        nv = normals(verts, faces)
        view(collect(zip(verts, nv)), faces)
    end
end


vert = """
#version 450
#extension GL_ARB_shader_draw_parameters : enable

struct VertexArgument{
    vec4 color;
    mat4 model;
};

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 normal;

layout (std140) uniform Scene{
    vec4 lightposition;
    mat4 proj;
    mat4 view;
    mat4 projview;
    vec2 resolution;
} scene;

layout (std140) uniform VertexArguments{
    VertexArgument[2048] args;
} vertex_arguments;


out VertexOut{
    vec3 vertex;
    vec3 normal;
    vec3 lightdir;
    vec4 color;
} vertex_out;

void main(){
    VertexArgument arg = vertex_arguments.args[gl_DrawIDARB];
    vec4 position_camspace = scene.view * arg.model * vec4(position,  1.0);
    gl_Position = scene.proj * position_camspace;
    vertex_out.lightdir = normalize(vec3(-10) - position.xyz);
    vertex_out.vertex = -position_camspace.xyz;
    vertex_out.normal = normal;
    vertex_out.color = arg.color;
}
"""

frag = """
#version 450

vec3 blinnphong(vec3 V, vec3 N, vec3 L, vec3 color){

    float diff_coeff = max(dot(L,N), 0.0);

    // specular coefficient
    vec3 H = normalize(L+V);

    float spec_coeff = pow(max(dot(H,N), 0.0), 8.0);
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return vec3(
        vec3(0.1) * vec3(0.3)  +
        vec3(0.9) * color * diff_coeff +
        vec3(0.3) * spec_coeff
    );
}

in VertexOut{
    vec3 vertex;
    vec3 normal;
    vec3 lightdir;
    vec4 color;
} vertex_in;

layout (location = 0) out vec4 frag_color;

void main(){
    vec3 L = normalize(vertex_in.lightdir);
    vec3 N = normalize(vertex_in.normal);
    vec3 light1 = blinnphong(vertex_in.vertex, N, L, vertex_in.color.rgb);
    vec3 light2 = blinnphong(vertex_in.vertex, N, -L, vertex_in.color.rgb);
    frag_color = vec4(light1 + light2, 1.0);
}
"""

window = create_glcontext(
    major = 4, minor = 5, debugging = false,
    windowhints = [
        (GLFW.SAMPLES,      0),
        (GLFW.DEPTH_BITS,   32),

        (GLFW.ALPHA_BITS,   8),
        (GLFW.RED_BITS,     8),
        (GLFW.GREEN_BITS,   8),
        (GLFW.BLUE_BITS,    8),

        (GLFW.STENCIL_BITS, 0),
        (GLFW.AUX_BUFFERS,  0)
    ]
)

events = WindowEvents(Window => window)

cam = PerspectiveCamera(
    TranslationSpeed => 1f0,
    LookAt => Vec3f0(0),
    EyePosition => Vec3f0(6, 6, 8),
    Rotation => Vec3f0(0),
    Area => events[Area],
    RotationSpeed => 0.1f0
)

for elem in (Mouse.Position, Mouse.Buttons, Mouse.Drag, Area, Keyboard.Buttons, Mouse.Scroll)
    add!(events, elem)
end

add!(cam, Translation, events,
    Mouse.right, Set([Keyboard.left_control])
)
add!(cam, Rotation, events,
    Mouse.left, Set([Keyboard.left_control])
)
add!(cam, Visualize.Projection, View)
add!(cam, EyePosition, LookAt)


cam[LookAt] = Vec3f0(0)
cam[EyePosition] = Vec3f0(3)
vertshader = compile_shader(Vector{UInt8}(vert), GL_VERTEX_SHADER, :vertexshader)
fragshader = compile_shader(Vector{UInt8}(frag), GL_FRAGMENT_SHADER, :fragshader)

program = compile_program(vertshader, fragshader)

scene = (
    Vec4f0(10),
    cam[Projection],
    cam[View],
    cam[ProjectionView],
    Vec2f0(widths(cam[Area]))
)

scene_buff = UniformBuffer(scene)
FieldTraits.on(cam, ProjectionView) do projview
    scene_buff[1] = (
        Vec4f0(10),
        cam[Visualize.Projection],
        cam[View],
        projview,
        Vec2f0(widths(cam[Area]))
    )
end

# Create empty Buffer
uniform_array = UniformBuffer(Tuple{Vec4f0, Mat4f0}, 1024 * 2)

function loadmeshes(folder)
    meshpaths = filter(x-> endswith(x, ".ifs"), readdir(folder))[1:1024]
    faces = GLTriangle[]
    vertices = Tuple{Point3f0, Normal{3, Float32}}[]
    v0 = (Point3f0(typemax(Float32)), Point3f0(typemin(Float32)))
    fidx = 0; vidx = 0;
    drawcommands = Vector{Command}(length(meshpaths))
    for (i, meshpath) in enumerate(meshpaths)
        mesh = read_ifs(joinpath(folder, meshpath))
        fs, vs = mesh.indexes[1], mesh.parent
        append!(faces, fs)
        ns = normals(vs, fs)
        append!(vertices, zip(vs, ns))
        mini, maxi = reduce((x, v)-> (min.(x[1], v), max.(x[2], v)), v0, mesh.parent)
        x, y = ind2sub((32, 32), i)
        trans = translationmatrix(Vec3f0(x, y, 0f0))
        s = maximum(maxi .- mini)
        scale = scalematrix(Vec3f0(1f0 ./ s))
        push!(uniform_array, (
            Vec4f0(rand(Vec3f0)..., 1f0),
            trans * scale * translationmatrix(-Vec3f0(mini))
        ))
        drawcommands[i] = Command(length(fs) * 3, 1, fidx, vidx, 0)
        fidx += length(fs) * 3; vidx += length(vs)
    end
    vbo = VertexArray(view(vertices, faces))
    ibuff = GLBuffer(drawcommands, buffertype = GL_DRAW_INDIRECT_BUFFER)
    vbo, ibuff
end

vbo, commandbuff = loadmeshes(homedir() * "/3dstuff/models")

sceneidx = glGetUniformBlockIndex(program, "Scene")
vertex_arts_idx = glGetUniformBlockIndex(program, "VertexArguments")

glUniformBlockBinding(program, sceneidx, 0)
glUniformBlockBinding(program, vertex_arts_idx, 1)
glBindBufferBase(GL_UNIFORM_BUFFER, 0, scene_buff.buffer.id)
glBindBufferBase(GL_UNIFORM_BUFFER, 1, uniform_array.buffer.id)


function rendloop(window, N, frame_times, commandbuff)
    glUseProgram(program)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_DEPTH_TEST)
    glDepthMask(GL_TRUE)
    glDepthFunc(GL_LEQUAL)
    glDisable(GL_CULL_FACE)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glClearColor(1, 1, 1, 1)
    GLAbstraction.bind(commandbuff)
    n = 0
    glBindVertexArray(vbo.id)
    while isopen(window) && n <= N
        tic()
        GLWindow.poll_glfw()
        GLAbstraction.@gputime begin
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

            glMultiDrawElementsIndirect(
                GL_TRIANGLES,
                GL_UNSIGNED_INT,
                C_NULL, length(commandbuff), 0
            )
            # glBindVertexArray(0)
            GLWindow.swapbuffers(window)
        end
        push!(frame_times, toq())
        n += 1
    end
    frame_times
end
times = Float64[]
rendloop(window, 60, times, commandbuff)
median(times) * 1000


GLFW.DestroyWindow(window)
window.handle = C_NULL

Profile.clear()
@profile rendloop(window, 2000, timsies)
Profile.print(noisefloor = 2.0)

#timsies = NTuple{3, Float64}[]
timsies = Float64[]
rendloop(window, timsies)
maximum(timsies) * 1000

mean(first.(timsies)) * 1000
mean(map(x->x[3], timsies)) * 1000

open("test.csv", "w") do io
    for t in timsies
        println(io, t)
    end
end
println(pwd())


for i = 1:100
    buzz = i % 5 == 0 ? "Buzz" : ""
    fizz = i % 3 == 0 ? "Fizz" : ""
    println(fizz*buzz)
    if buzz || fizz
        if fizz && buzz
            println("FizzBuzz")
        else
            fizz && println("Buzz")
            buzz && println("Buzz")
        end
    else
        println(i)
    end
end
