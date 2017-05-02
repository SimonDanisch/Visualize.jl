using GLAbstraction, GLVisualize, GeometryTypes, Colors, ModernGL, Reactive
import GLVisualize: glyph_bearing!, glyph_uv_width!, glyph_scale!, get_texture_atlas
import GLVisualize: get_texture_atlas, defaultfont, glyph_advance!, isnewline

if !isdefined(:Particle)
abstract Particle
immutable Sprite{N, T} <: Particle
    position::Point{N, T}
    offset::Vec{2, T}
    scale::Vec{2, T}
    uv::Vec{4, T}
    color::RGBA{Float32}
end
type Text
    data
    text
    atlas
    cursors
    # default values
    font
    scale
    offset
    color
    startposition
    lineheight
end
const GLSprite2 = Sprite{2, Float32}
const GLSprite3 = Sprite{3, Float32}
end

function Sprite{N, T}(
        char, position::Point{N, T}, text
    )
    Sprite(
        char, position, text.scale, text.offset,
        text.color, text.font, text.atlas
    )
end

function Sprite{N, T}(
        char, position::Point{N, T}, scale, offset, color,
        font = defaultfont(),  atlas = get_texture_atlas()
    )
    Sprite{N, T}(
        position,
        glyph_bearing!(atlas, char, font, scale) + offset,
        glyph_scale!(atlas, char, font, scale),
        glyph_uv_width!(atlas, char, font),
        color
    )
end


function nextposition(sprite::Sprite, char, text)
    advance_x, advance_y = glyph_advance!(text.atlas, char, text.font, text.scale)
    position = sprite.position
    if isnewline(char)
        return Point2f0(text.startposition[1], position[2] - advance_y * text.lineheight) #reset to startx
    else
        return position + Point2f0(advance_x, 0)
    end
end

function printat(text::Text, idx::Integer, char::Char)
    position = if checkbounds(Bool, text.data, idx)
        sprite = text.data[idx]
        nextposition(sprite, text.text[idx], text)
    else
        text.startposition
    end
    nextsprite = Sprite(char, position, text)
    idx += 1
    insert!(text.data, idx, nextsprite)
    insert!(text.text, idx, char)
    idx
end
function printat(text::Text, idx::Int, str::String)
    sprite = text.data[idx]
    position = sprite.position
    for char in str
        char == '\r' && continue # stupid windows!
        idx = printat(text, idx, char)
    end
    idx
end

function Base.print(text::Text, char::Union{Char, String})
    map!(text.cursors) do idx
        idx = printat(text, idx, char)
        return idx
    end
    nothing
end
function Base.String(text::Text)
    join(text.text)
end

import GLVisualize: mm
w = glscreen(debugging = true)

text = Text(
    GLSprite2[],
    Char[],
    get_texture_atlas(),
    [0],
    defaultfont(),
    5mm,
    0f0,
    RGBA(0f0, 0f0, 0f0, 1f0),
    Point2f0(0),
    1.5
)
print(text, 'c')
@time print(text, " sexsex");
text.color = RGBA(1f0, 0f0, 0f0, 1f0)
@time print(text, " Muashahahaha@");

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
