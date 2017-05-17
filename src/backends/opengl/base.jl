module GLRasterization

using ModernGL, GLFW
using Colors, ColorVectorSpace, StaticArrays, GeometryTypes
import GLAbstraction
using GLAbstraction: GLBuffer, Shader, compile_shader, Texture

import Transpiler
using Transpiler: emit_vertex_shader, emit_geometry_shader, emit_fragment_shader, glsl_gensym
import Transpiler: gli

using FieldTraits
using FieldTraits: @reactivecomposed, @field, @composed, @needs
using FieldTraits: Composable, ComposableLike, Field, UsageError, Fields, Links
using FieldTraits: ReactiveComposable, Parent
import FieldTraits: on, default

using Visualize: WindowEvents, Area, Window, Mouse, Keyboard, Visible, Focused
using Visualize: Debugging, Name, AbstractWindow, DroppedFiles, Open
import Visualize: add!, IRect


include("glutils.jl")
include("glfw.jl")
include("rasterpipeline.jl")

export UniformBuffer, VertexArray, GLFWWindow, GLRasterizer

end
