#version 330
// dependant type declarations
// Julia name: Symbol
struct Symbol{
    float empty; // structs can't be empty
};

// Julia name: Canvas
struct Canvas{
    vec2 resolution;
    mat4 projection;
    mat4 view;
    mat4 projectionview;
};

// Julia name: Uniforms
struct Uniforms{
    mat4 model;
    float thickness;
    float pattern_length;
};

// Julia name: LineVertex{2}
struct LineVertex_2{
    vec2 position;
    float thickness;
    vec4 color;
};

// Julia name: Vert2Geom
struct Vert2Geom{
    vec4 position;
    vec4 color;
    float thickness;
};

// dependant function declarations
float get_thickness(LineVertex_2 x, Uniforms uniforms)
{
    return x.thickness;
}
vec4 get_color(LineVertex_2 x, Uniforms uniforms)
{
    return x.color;
}
vec2 get_position(LineVertex_2 x)
{
    return x.position;
}
vec4 to_vec4(vec2 v)
{
    return vec4(v.x, v.y, 0.0, 1.0);
}
// vertex input:
layout (location = 0) in vec2 vertex_position;
layout (location = 1) in float vertex_thickness;
layout (location = 2) in vec4 vertex_color;
// uniform inputs:
layout (std140) uniform _gensymed_UniformArg1{
    Canvas canvas;
};

layout (std140) uniform _gensymed_UniformArg2{
    Uniforms uniforms;
};

out Vert2Geom vertex_out;

// vertex main function:
void main()
{
    LineVertex_2 vertex;
    vertex = LineVertex_2(vertex_position, vertex_thickness, vertex_color);
    Vert2Geom geomout;
    vec4 pos;
    pos = to_vec4(get_position(vertex));
    geomout = Vert2Geom(pos, get_color(vertex, uniforms), get_thickness(vertex, uniforms));
    vertex_out = geomout;
}


#version 330
layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;
// dependant type declarations
// Julia name: Geom2Fragment
struct Geom2Fragment{
    float thickness;
    vec4 color;
    vec2 uv;
};

// Julia name: Uniforms
struct Uniforms{
    mat4 model;
    float thickness;
    float pattern_length;
};

// Julia name: Visualize.GLRasterization.#emit_placeholder
struct Visualize1GLRasterization12emit_placeholder{
    float empty; // structs can't be empty
};

// Julia name: Symbol
struct Symbol{
    float empty; // structs can't be empty
};

// Julia name: Vert2Geom
struct Vert2Geom{
    vec4 position;
    vec4 color;
    float thickness;
};

// Julia name: Canvas
struct Canvas{
    vec2 resolution;
    mat4 projection;
    mat4 view;
    mat4 projectionview;
};

in Vert2Geom vertex_out[2];
out Geom2Fragment geom_out;
// uniform inputs:
layout (std140) uniform _gensymed_UniformArg1{
    Canvas canvas;
};

layout (std140) uniform _gensymed_UniformArg2{
    Uniforms uniforms;
};

// dependant function declarations
void emit_vertex2(Visualize1GLRasterization12emit_placeholder emit3, Vert2Geom[2] geom_in, Canvas canvas, Uniforms uniforms, vec2 position, vec2 uv, int index)
{
    Geom2Fragment fragout;
    vec4 outpos;
    vec2 x;
    vec4 inpos;
    inpos = geom_in[index - 1].position;
    x = (position / vec2(1024.0, 1024.0)) * inpos.w;
    outpos = vec4(x.x, x.y, inpos.z, inpos.w);
    fragout = Geom2Fragment(geom_in[index - 1].thickness + 2.0, geom_in[index - 1].color, uv);
    gl_Position = outpos;
    geom_out = fragout;
    EmitVertex();
    ;
}
vec2 screen_space(vec4 vertex, Canvas canvas)
{
    return (vertex.xy / vertex.w) * canvas.resolution;
}

// geometry main function:
void main()
{
    Visualize1GLRasterization12emit_placeholder emit3;
    float uv1;
    float uv0;
    float l;
    vec2 n0;
    vec2 v0;
    vec2 vun0;
    float thickness_aa1;
    float thickness_aa0;
    vec2 p1;
    vec2 p0;
    p0 = screen_space(vertex_out[0].position, canvas);
    p1 = screen_space(vertex_out[1].position, canvas);
    thickness_aa0 = 20.0 + 2.0;
    thickness_aa1 = 20.0 + 2.0;
    vun0 = p1 - p0;
    v0 = normalize(vun0);
    n0 = vec2(-(v0.y), v0.x);
    l = length(p1 - p0);
    uv0 = thickness_aa0 / 20.0;
    uv1 = thickness_aa1 / 20.0;
    emit_vertex2(emit3, vertex_out, canvas, uniforms, p0 + thickness_aa0 * n0, vec2(0.0, -uv0), 1);
    emit_vertex2(emit3, vertex_out, canvas, uniforms, p0 - thickness_aa0 * n0, vec2(0.0, uv0), 1);
    emit_vertex2(emit3, vertex_out, canvas, uniforms, p1 + thickness_aa1 * n0, vec2(l, -uv1), 2);
    emit_vertex2(emit3, vertex_out, canvas, uniforms, p1 - thickness_aa1 * n0, vec2(l, uv1), 2);
    EndPrimitive();
}

#version 330
// dependant type declarations
// Julia name: Uniforms
struct Uniforms{
    mat4 model;
    float thickness;
    float pattern_length;
};

// Julia name: Canvas
struct Canvas{
    vec2 resolution;
    mat4 projection;
    mat4 view;
    mat4 projectionview;
};

// Julia name: Symbol
struct Symbol{
    float empty; // structs can't be empty
};

// Julia name: Geom2Fragment
struct Geom2Fragment{
    float thickness;
    vec4 color;
    vec2 uv;
};

// dependant function declarations
float aastep(float threshold1, float threshold2, float value)
{
    float afwidth;
    afwidth = float(0.001);
    return smoothstep(threshold1 - afwidth, threshold1 + afwidth, value) - smoothstep(threshold2 - afwidth, threshold2 + afwidth, value);
}
float aastep(float threshold1, float value)
{
    return smoothstep(threshold1 - float(0.001), threshold1 + float(0.001), value);
}
// uniform inputs:
layout (std140) uniform _gensymed_UniformArg1{
    Canvas canvas;
};

layout (std140) uniform _gensymed_UniformArg2{
    Uniforms uniforms;
};

in Geom2Fragment geom_out;
layout (location = 0) out vec4 _gensymed_color0;

// fragment main function:
void main()
{
    vec4 outcolor;
    float alpha2;
    float alpha;
    vec2 xy;
    vec4 color;
    vec2 uv;
    uv = geom_out.uv;
    color = geom_out.color;
    xy = vec2(0.5, uv.y);
    alpha = aastep(0.0, xy.x);
    alpha2 = aastep(-1.0, 1.0, xy.y);
    outcolor = vec4(color.x, color.y, color.z, color.w * alpha * alpha2);
    _gensymed_color0 = vec4(1, 0, 0, 1);
}
