# using Visualize: vert_linesegments, frag_linesegments, geom_linesegments, LineSegments, Vertices, LineAttributes
#
#
# function Drawable(w::AbstractGLWindow, primitive::LineSegments)
#     vbo = VertexArray(primitive[Vertices], face_type = Face{2, OffsetInteger{1, GLint}})
#     uniforms = UniformBuffer(LineAttributes(primitive))
#     args = (w[Scene], uniforms)
#     rasterizer(
#         vbo, args,
#         vert_linesegments, frag_linesegments;
#         geometryshader = geom_linesegments,
#         primitive_in = :lines
#     )
# end
