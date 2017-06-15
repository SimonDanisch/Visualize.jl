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
using FieldTraits: ReactiveComposable, Partial
import FieldTraits: on, default

using Visualize: WindowEvents, Area, Window, Mouse, Keyboard, Visible, Focused
using Visualize: Debugging, Name, AbstractWindow, DroppedFiles, Renderlist, Open
using Visualize: Projection, NativeWindow, ProjectionView, Resolution, Camera
using Visualize: EyePosition, View, Scene, SceneUniforms, NativeWindowEvents
using Visualize: LookAt, PerspectiveCamera, Translation, Rotation, Pan, Zoom, poll_actions

import Visualize: add!, IRect, show!, destroy!, swapbuffers!, Drawable


include("glutils.jl")
include("glfw.jl")
include("gtk.jl")
include("rasterpipeline.jl")
include("lines.jl")

export UniformBuffer, VertexArray, GLFWWindow, GLRasterizer

end
