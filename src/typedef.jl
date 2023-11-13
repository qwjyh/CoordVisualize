using Dates
import Base
"""
Stores a set of logs with its taken date datetime and supplemental note.
"""
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

Base.:(==)(x::CoordLog, y::CoordLog) = begin
    x.note == y.note && x.logdate == y.logdate && x.coords == y.coords
end
