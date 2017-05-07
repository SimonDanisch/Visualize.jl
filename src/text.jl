using GLAbstraction, GLVisualize, GeometryTypes, Colors, ModernGL, Reactive
import GLVisualize: glyph_bearing!, glyph_uv_width!, glyph_scale!, get_texture_atlas
import GLVisualize: get_texture_atlas, defaultfont, glyph_advance!, isnewline

if !isdefined(:Particle)


import GLVisualize: mm
w = glscreen(debugging = true)


buffer = GLBuffer{eltype(text.data)}(
        pointer(text.data), length(text.data),
    GL_ARRAY_BUFFER, GL_DYNAMIC_DRAW
)

shader = GLVisualize.GLVisualizeShader(
    "fragment_output.frag", "util.vert", "sprites.geom",
    "sprites.vert", "distance_shape.frag",
    view = Dict(
        "position_calc" => "pos = vec3(position, 0);",
        "position_type" => "in vec2 ",
        "offset_type" => "in vec2 ",
        "uv_offset_width_type" => "in vec4 ",
        "color_type" => "in vec3 ",
        "scale_type" => "in vec2 ",
        "color_map_type" => "Nothing ",
        "intensity_type" => "Nothing ",
        "color_norm_type" => "Nothing ",

        "position_x_type" => "Nothing ",
        "position_y_type" => "Nothing ",
        "position_z_type" => "Nothing ",

        "scale_x_type" => "Nothing ",
        "scale_y_type" => "Nothing ",
        "scale_z_type" => "Nothing ",
        "image_type" => "Nothing ",
    )
)

data = Dict(
    :glow_color      => RGBA{Float32}(0,0,0,0),
    :stroke_color    => RGBA{Float32}(0,0,0,0),
    :rotation        => Vec3f0(0,0,1),
    :stroke_width    => 0f0,
    :glow_width      => 0f0,
    :distancefield   => text.atlas.images,
    :model           => eye(Mat4f0),
    :visible         => true,
    # rotation and billboard don't go along
    :billboard       => true,
    :fxaa            => false,
    :len => length(text.data),
    :scale_primitive => false,
    :shape => Int32(GLVisualize.DISTANCEFIELD),
    :resolution => map(area-> Vec2f0(widths(area)), w.area)
)
program = GLAbstraction.gl_convert(shader, data)

vbo = GLVertexArray(buffer, program)
gl_data = map(data) do kv
    kv[1] => GLAbstraction.gl_convert(kv[2])
end;
length(vbo)
postrender = ()-> begin
    glDrawArrays(GL_POINTS, 0, length(text.data))
end
robj = RenderObject{GLAbstraction.StandardPrerender}(
    nothing,
    gl_data, vbo,
    GLAbstraction.StandardPrerender(),
    postrender,
    Signal(AABB{Float32}(Vec3f0(0), Vec3f0(1)))
)
@async renderloop(w)

_view(robj, w, camera = :orthographic_pixel)
