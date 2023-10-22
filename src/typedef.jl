using Dates
struct CoordLog{T <: AbstractFloat}
    coords::Matrix{T}
    logdate::DateTime
    note::String
end

