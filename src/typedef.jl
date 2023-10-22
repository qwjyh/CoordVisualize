using Dates
mutable struct CoordLog{T <: AbstractFloat}
    coords::Matrix{T}
    logdate::DateTime
    note::String
end

"""
    n_coords(log::CoordLog)::Integer

Get number of coordinates in `log`.
"""
function n_coords(log::CoordLog)::Integer
    size(log.coords)[1]
end
