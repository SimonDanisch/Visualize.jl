using Visualize, GeometryTypes, ModernGL
using Visualize: GLRasterization, TextUniforms, get_texture_atlas, Sprite2, STDCanvas, getposition

resolution = (1024, 1024)

proj = orthographicprojection(SimpleRectangle(0, 0, resolution...), -10_000f0, 10_000f0)

canvas = STDCanvas(
    proj,
    eye(Mat4f0),
    proj,
    resolution
)

atlas = get_texture_atlas();

text = Visualize.Text(
    Sprite2[],
    Char[],
    atlas,
    [0],
    Visualize.defaultfont(),
    45f0,
    0f0,
    Vec4f0(0f0, 0f0, 0f0, 1f0),
    Point2f0(0),
    1.5
);

print(text, 'c')
print(text, " nice test bro!")
text.color = Vec4f0(1f0, 0f0, 0f0, 1f0)
print(text, " Muashahahaha@")


c = CairoRGBSurface(resolution...);
cr = CairoContext(c);
save(cr);
set_source_rgb(cr, 1.0, 1.0, 1.0);    # light gray
rectangle(cr, 0.0, 0.0, resolution...); # background
fill(cr);
restore(cr);

save(cr);

function draw_text(cr, text, canvas, uniforms)
    #set_font_face(cr, text.font)
    for (c, sprite) in zip(text.text, text.data)
        pos = getposition(sprite)
        pos = canvas.projectionview * #=uniforms.model * =# Visualize.to_vec4(Vec2f0(pos))
        pos2d = clip2pixel_space(pos, canvas.resolution)
        pos2d = Vec2f0(pos2d[1], resolution[2] - pos2d[2])
        scale = sprite.scale
        move_to(cr, pos2d...)
        set_source_rgba(cr, sprite.color...)
        set_font_size(cr, scale[2])
        show_text(cr, string(c))
    end
end
draw_text(cr, text, canvas, uniforms)
write_to_png(c, "sample_dash.png")
