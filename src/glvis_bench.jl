using GeometryTypes, Colors, GLVisualize, GLWindow, FileIO, GLAbstraction

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
                read(io, UInt32),
                read(io, UInt32),
                read(io, UInt32)
            )
        end
        GLNormalMesh(vertices = verts, faces = faces)
    end
end


function display_data(folder)
    meshpaths = filter(x-> endswith(x, ".ifs"), readdir(folder))[1:1024]
    meshpaths = [meshpaths; meshpaths]
    v0 = (Point3f0(typemax(Float32)), Point3f0(typemin(Float32)))
    for (i, meshpath) in enumerate(meshpaths)
        mesh = read_ifs(joinpath(folder, meshpath))
        if isempty(mesh.vertices)
            println("lol?")
            continue
        end
        mini, maxi = extrema(mesh.vertices)
        x, y = ind2sub((32, 32), i)
        trans = translationmatrix(Vec3f0(x, y, 0f0))
        s = maximum(maxi .- mini)
        scale = scalematrix(Vec3f0(1f0 ./ s))
        _view(visualize(
            mesh,
            color = RGBA{Float32}(rand(RGB{Float32}), 1f0),
            model = trans * scale * translationmatrix(-Vec3f0(mini))
        ))
    end
end
window = glscreen()
display_data(homedir() * "/3dstuff/models")



function rendloop(window, frame_times)
    while isopen(window)
        tic()
        glFinish()
        render_frame(window)
        GLWindow.swapbuffers(window)
        GLWindow.poll_glfw()
        GLWindow.poll_reactive()
        push!(frame_times, toq())
    end
    GLFW.DestroyWindow(window)
    window.handle = C_NULL
    frame_times
end
timsies = Float64[]
rendloop(window, timsies)


open("/home/s/.julia/v0.6/Visualize/test2.csv", "w") do io
    for t in timsies
        println(io, t)
    end
end
println(pwd())
