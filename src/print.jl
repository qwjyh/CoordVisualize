"""
Export `log` to a file or `io::IO`.
"""
function export_log end

function export_log(log::CoordLog)
    """
    CoordLog(
        $(log.coords),
        Dates.DateTime("$(log.logdate)"), "$(log.note)"
    )"""
end

function export_log(logs::Vector{CoordLog})
    logs .|>
        export_log |>
        (vs -> join(vs, ",\n")) |>
        (s -> "[\n" * s * "\n]")
end

"""
    export_log(io::IO, log)
"""
function export_log(io::IO, log)
    write(io, export_log(log))
end

"""
    export_log(file::AbstractString, log)
"""
function export_log(file::AbstractString, log)
    open(file, "w") do f
        export_log(f, log)
    end
end

