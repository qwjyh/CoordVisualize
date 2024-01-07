"""
    split_log(log::CoordLog, at::Unsigned, notes_1::AbstractString, notes_2::AbstractString)::Vector{CoordLog}

Split `log` at `at`, i.e. to `1:at` and `(at + 1):end` then assign `notes_1` and `notes_2` to notes for each other.
"""
function split_log(
    log::CoordLog,
    at::Unsigned,
    notes_1::AbstractString,
    notes_2::AbstractString,
)::Tuple{CoordLog, CoordLog}
    @assert at < size(log.coords)[1] "Split index must be less than original log length($(size(log.coords)[1]))"
    (
        CoordLog(log.coords[1:at, :], log.logdate, notes_1),
        CoordLog(log.coords[(at + 1):end, :], log.logdate, notes_2),
    )
end

function split_log(
    log::CoordLog,
    at::Integer,
    notes_1::AbstractString,
    notes_2::AbstractString,
)::Tuple{CoordLog, CoordLog}
    split_log(log, UInt(at), notes_1, notes_2)
end

"""
    assign_note!(log::CoordLog, new_note::AbstractString)

Replace `note` in `log` with `new_note`.
"""
function assign_note!(log::CoordLog, new_note::AbstractString)
    log.note = new_note
end

"""
    join_log(
        log1::CoordLog{T},
        log2::CoordLog{T},
        note::AbstractString,
    )::CoordLog{T} where {T}

Join two logs.
"""
function join_log(
    log1::CoordLog{T},
    log2::CoordLog{T},
    note::AbstractString,
)::CoordLog{T} where {T}
    newdate = min(log1.logdate, log2.logdate)
    CoordLog(vcat(log1.coords, log2.coords), newdate, note)
end
