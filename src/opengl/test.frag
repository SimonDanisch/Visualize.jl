{{GLSL_VERSION}}

in vec2 o_uv;
uniform sampler2D image;

out vec4 fragment_color;

void main(){
    fragment_color = texture(image, o_uv);
}
