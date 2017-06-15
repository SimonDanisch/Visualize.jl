immutable UVWVertex
    position::Vec3f0
    uvw::Vec3f0
end

immutable Uniforms{SV, BF, CF, AF}
    model::Mat4f0
    modelinv::Mat4f0
    isovalue::Float32
    startvalue::SV
    breakloop::BF
    to_color::CF
    accumulation::AF
end

function vert_volume(vertex, canvas, uniforms, intensities)
    world_vert = uniforms.model * Visualize.to_vec4(vertex.position)
    pos = canvas.projectionview * world_vert
    return (
        pos,
        UVWVertex(world_vert[Vec(1, 2, 3)], vertex.uvw)
    )
end

function is_outside(position::Vec3f0)
    position[1] > 1f0 || position[2] > 1f0 ||
    position[3] > 1f0 || position[1] < 0f0 ||
    position[2] < 0f0 || position[3] < 0f0
end

function mip(accum, pos, stepdir, intensities, uniforms)
    max(accum, intensities[pos][1])
end

function raycast_loop(
        front::Vec3f0, dir::Vec3f0, num_samples, stepsize::Float32,
        uniforms, intensities
    )
    stepsize_dir = dir * stepsize
    pos = front
    pos += stepsize_dir; # apply first, to padd
    accumulator = uniforms.startvalue
    for i = 1:num_samples
        if uniforms.breakloop(accumulator) || is_outside(pos)
            break
        end
        accumulator = uniforms.accumulation(
            accumulator, pos, stepsize_dir, intensities, uniforms
        )
        pos += stepsize_dir
    end
    return uniforms.to_color(accumulator, uniforms)
end

function frag_volume(vertex_out, canvas, uniforms, intensities)
    max_distance = 1.73f0
    num_samples = 128
    step_size = max_distance / Float32(num_samples)
    dir = normalize(vertex_out.position - canvas.eyeposition)
    dir = (uniforms.modelinv * Vec4f0(dir[1], dir[2], dir[3], 0f0))[Vec(1, 2, 3)]
    color = raycast_loop(vertex_out.uvw, dir, num_samples, step_size, uniforms, intensities)
    (color, )
end
