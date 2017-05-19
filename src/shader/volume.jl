immutable Vertex2Fragment
    vert::Vec3f0
    uvw::Vec3f0
end
immutable Canvas
    eyeposition::Vec3f0
end
immutable Uniforms{F}
    model::Mat4f0
    modelinv::Mat4f0
    isovalue::Float32
    isorange::Float32
    algorithm::F
end

const max_distance = 1.0
const num_samples = 128
const step_size = max_distance / float(num_samples)
const num_ligth_samples = 16
const lscale = max_distance / float(num_ligth_samples)
const density_factor = 9

function is_outside(position::Vec3f0)
    position.x > 1.0 || position.y > 1.0 ||
    position.z > 1.0 || position.x < 0.0 ||
    position.y < 0.0 || position.z < 0.0)
end

function mip(accum, pos, stepdir, intensities, uniforms)
    max(maximum, intensities[pos])
end

function raycast_loop(
        front::Vec3f0, dir::Vec3f0, stepsize::Float32,
        accumulation, breakloop, to_color, startvalue,
        intensities, uniforms
    )
    stepsize_dir = dir * stepsize
    pos = front
    pos += stepsize_dir; # apply first, to padd
    accumulator = startvalue
    i = 0
    while (i < num_samples && !is_outside(pos))
        accumulator = accumulation(accumulator, pos, stepdir, intensities, uniforms)
        if breakloop(accumulator)
            break
        end
        pos += stepsize_dir; i += 1
    end
    return to_color(accumulator, uniforms)
end


function frag_volume()
    Vec3f0 dir = normalize(frag_vert - eyeposition);
    dir = Vec3f0(modelinv * Vec4f0(dir, 0));
    color = isosurface(frag_uv, dir, step_size);
end
