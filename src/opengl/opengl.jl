@typealias GLImage(::Image) <: GLShared begin
    "image, can be a Texture or Array of colors"
    ImageData::Texture
    "The geometry the image is mapped to. Can be a 2D Geometry or mesh"
    Primitive::GLUVMesh <= Range
    SpatialOrder
end


function Base.convert(::GLImage, spatialorder::Primitive, value::Image)
    range = value[Range]
    x, y = minimum(r[1]), minimum(r[2])
    xmax, ymax = maximum(r[1]), maximum(r[2])
    SimpleRectangle{Float32}(x, y, xmax - x, ymax - y)
end

function show(canvas::GLCanvas, glimage::GLImage)
    shader = GLVisualizeShader(
        "fragment_output.frag", "uv_vert.vert", "texture.frag",
        view = Dict("uv_swizzle" => "o_uv.$(spatialorder)")
    )
end
