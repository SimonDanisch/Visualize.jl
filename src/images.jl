@field ImageData
@field SpatialOrder begin
    
@field Ranges

@composed type Image
    ImageData
    Ranges
    SpatialOrder::Tuple{Integer, Integer}
    Transform
end
function Base.convert(::Image, spatialorder::SpatialOrder, value)
    if !(spatialorder in (:xy, :yx))
        error("Spatial order only accepts :xy or :yz as a value. Found: $spatialorder")
    end
    spatialorder == :xy ? (1, 2) : (2, 1)
end
default(x::Image, ::SpatialOrder) = (1, 2)

function default(x::Image, ::Ranges)
    data = x[Data]
    spatialorder = x[SpatialOrder]
    (
        0:size(m, s === :xy ? 1 : 2),
        0:size(m, s === :xy ? 2 : 1)
    )
end
