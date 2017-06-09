#version 330
// dependant type declarations
// Julia name: Symbol
struct Symbol{
    float empty; // structs can't be empty
};

// Julia name: Visualize.Vertex2Geom
struct Vertex2Geom{
    vec4 uvrect;
    vec4 color;
    vec4 rect;
};

// Julia name: Visualize.TextUniforms
struct TextUniforms{
    mat4 projection;
    vec4 strokecolor;
    vec4 glowcolor;
};

// Julia name: Visualize.Sprite{2,Float32}
struct Sprite_2_float{
    vec2 position;
    vec2 offset;
    vec2 scale;
    vec4 uv;
    vec4 color;
};

// dependant function declarations
vec4 getcolor(Sprite_2_float x)
{
    return x.color;
}
vec4 getuvrect(Sprite_2_float x)
{
    return x.uv;
}
vec2 getscale(Sprite_2_float x)
{
    return x.scale;
}
vec2 getposition(Sprite_2_float x)
{
    return x.position;
}
Vertex2Geom vertex_main(Sprite_2_float vertex, TextUniforms uniforms)
{
    Vertex2Geom geom;
    vec2 scale;
    vec2 p;
    p = getposition(vertex);
    scale = getscale(vertex);
    geom = Vertex2Geom(getuvrect(vertex), getcolor(vertex), vec4(p.x, p.y, scale.x, scale.y));
    return geom;
}
// vertex input:
layout (location = 0) in vec2 vertex_position;
layout (location = 1) in vec2 vertex_offset;
layout (location = 2) in vec2 vertex_scale;
layout (location = 3) in vec4 vertex_uv;
layout (location = 4) in vec4 vertex_color;
// uniform inputs:
layout (std140) uniform _gensymed_UniformArg1{
    TextUniforms uniforms;
};

uniform sampler2D image;
out Vertex2Geom vertex_out;

// vertex main function:
void main()
{
    Sprite_2_float vertex;
    vertex = Sprite_2_float(vertex_position, vertex_offset, vertex_scale, vertex_uv, vertex_color);
    vertex_out = vertex_main(vertex, uniforms);
}---------------------------
#version 330
layout(points) in;
layout(triangle_strip, max_vertices = 4) out;
// dependant type declarations
// Julia name: Visualize.Vertex2Geom
struct Vertex2Geom{
    vec4 uvrect;
    vec4 color;
    vec4 rect;
};

// Julia name: Tuple{GeometryTypes.Vec{2,Float32},GeometryTypes.Vec{4,Float32}}
struct Tuple_vec2_vec4{
    vec2 field1;
    vec4 field2;
};

// Julia name: Symbol
struct Symbol{
    float empty; // structs can't be empty
};

// Julia name: Visualize.TextUniforms
struct TextUniforms{
    mat4 projection;
    vec4 strokecolor;
    vec4 glowcolor;
};

// Julia name: Visualize.GLRasterization.#emit_placeholder
struct Visualize1GLRasterization12emit_placeholder{
    float empty; // structs can't be empty
};

in Vertex2Geom geom_in[];
out Tuple_vec2_vec4 geom_out;
// uniform inputs:
layout (std140) uniform _gensymed_UniformArg1{
    TextUniforms uniforms;
};

uniform sampler2D image;
// dependant function declarations
void emit_vertex(Visualize1GLRasterization12emit_placeholder emit3, vec2 vertex, vec2 uv, Vertex2Geom arg, vec2 pos, TextUniforms uniforms)
{
    vec4 final_position;
    vec4 datapoint;
    datapoint = uniforms.projection * vec4(pos.x, pos.y, 0, 1);
    final_position = uniforms.projection * vec4(vertex.x, vertex.y, 0, 0);
    gl_Position = datapoint + final_position;
    geom_out = Tuple_vec2_vec4(uv, arg.color);
    EmitVertex();
    ;
}
void geometry_main(Visualize1GLRasterization12emit_placeholder emit3, Vertex2Geom[1] geom_in, TextUniforms uniforms)
{
    vec4 uv;
    vec4 quad;
    vec2 scale;
    vec2 pos;
    vec4 pos_scale;
    Vertex2Geom arg;
    arg = geom_in[0];
    pos_scale = arg.rect;
    pos = pos_scale.xy;
    scale = pos_scale.zw;
    quad = vec4(0.0, 0.0, scale.x, scale.y);
    uv = arg.uvrect;
    emit_vertex(emit3, quad.xy, uv.xw, arg, pos, uniforms);
    emit_vertex(emit3, quad.xw, uv.xy, arg, pos, uniforms);
    emit_vertex(emit3, quad.zy, uv.zw, arg, pos, uniforms);
    emit_vertex(emit3, quad.zw, uv.zy, arg, pos, uniforms);
    ;
}

// geometry main function:
void main()
{
    Visualize1GLRasterization12emit_placeholder emit3;
    EndPrimitive();
}
---------------------------
#version 330
// dependant type declarations
// Julia name: Visualize.TextUniforms
struct TextUniforms{
    mat4 projection;
    vec4 strokecolor;
    vec4 glowcolor;
};

// Julia name: Symbol
struct Symbol{
    float empty; // structs can't be empty
};

// Julia name: Tuple{GeometryTypes.Vec{2,Float32},GeometryTypes.Vec{4,Float32}}
struct Tuple_vec2_vec4{
    vec2 field1;
    vec4 field2;
};

// dependant function declarations
float aastep(float threshold1, float value)
{
    return smoothstep(threshold1 - float(0.001), threshold1 + float(0.001), value);
}
vec4 getindex(sampler2D x, vec2 idx)
{
    return texture(x, idx);
}
// uniform inputs:
layout (std140) uniform _gensymed_UniformArg1{
    TextUniforms uniforms;
};

uniform sampler2D image;
in Tuple_vec2_vec4 geom_out;
layout (location = 0) out vec4 _gensymed_color0;

// fragment main function:
void main()
{
    vec4 bg;
    float inside;
    float signed_distance;
    vec4 color;
    vec2 uv;
    uv = geom_out.field1;
    color = geom_out.field2;
    signed_distance = -(getindex(image, uv).x);
    inside = aastep(0.0, signed_distance);
    bg = vec4(1.0, 1.0, 1.0, 0.0);
    _gensymed_color0 = mix(bg, color, inside);
}
