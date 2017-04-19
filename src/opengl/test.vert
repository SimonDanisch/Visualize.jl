{{GLSL_VERSION}}

layout(binding = 0) uniform Canvas
{
    vec2 resolution;
    mat4 projection;
    mat4 view;
    mat4 PxVxM; // projection * view * model matrix
};

layout(location = 1) in vec2 position;
layout(location = 2) in vec2 texturecoordinate;

out vec2 o_uv;

void main(){
    o_uv = texturecoordinate;
    gl_Position = Canvas.PxVxM * vec4(position, 0, 1);
}
