"""
    split_log(log::CoordLog, at::Unsigned, notes_1::AbstractString, notes_2::AbstractString)::Vector{CoordLog}

Split `log` at `at`, i.e. to `1:at` and `at:end` then assign `notes_1` and `notes_2` to notes for each other.
"""
function split_log(log::CoordLog, at::Unsigned, notes_1::AbstractString, notes_2::AbstractString)::Vector{CoordLog}
    @assert at < size(log.coords)[1] "Split index must be less than original log length($(size(log.coords)[1]))"
    [
        CoordLog(log.coords[1:at, :], log.logdate, notes_1),
        CoordLog(log.coords[at:end, :], log.logdate, notes_2),
    ]
end

function split_log(log::CoordLog, at::Integer, notes_1::AbstractString, notes_2::AbstractString)::Vector{CoordLog}
    split_log(log, UInt(at), notes_1, notes_2)
end


"""
    assign_note!(log::CoordLog, new_note::AbstractString)

Replace `note` in `log` with `new_note`.
"""
function assign_note!(log::CoordLog, new_note::AbstractString)
    log.note = new_note
end
