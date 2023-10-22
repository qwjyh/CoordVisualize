using CoordVisualize: CoordLog
using Dates

"""
    parse_log(filepath::AbstractString; interactive=false)::Vector{CoordLog}

Parse raw coordinates log from tracecoords to vector of `CoordLog`.
Each logging is converted to one `CoordLog`.

If keyword argument `interactive` is set to `true`, prompts will be shown to
receive custom notes for each `CoordLog`.
Otherwise the note is set to ""(empty string).
"""
function parse_log(filepath::AbstractString; interactive=false)::Vector{CoordLog}
    istracing::Bool = false
    coords_trace = Vector{Vector{Float64}}(undef, 0) # SVector ?
    ret = Vector{CoordLog}()
    log_date = DateTime(0)
    for (i, l) in enumerate(readlines(filepath))
        # skip logs not from tracecoord
        if match(r"^\[TRACECOORDS\]", l) |> isnothing
            continue
        end
        if !istracing
            # not tracing

            # if starting
            if match(r"Logging starting", l) |> !isnothing
                @debug "Logging started at l:$(i)"
                istracing = true
                coords_trace = Vector{Vector{Float64}}(undef, 0) # SVector ?
                log_date = try
                    s = match(r"\".+\"").match
                    parse(DateTime, s[2:end-1])
                catch e
                    @error "Failed to parse date at line $(i), file $(filepath)"
                    DateTime(0)
                end
            end
        else
            if match(r"Logging stopping", l) |> !isnothing
                @debug "Logging stopped at l:$(i)"
                istracing = false

                # get note in interactive parsing
                if interactive
                    println("type note for the log at $(log_date)UTC")
                    note = readline()
                else
                    note = ""
                end

                coords_trace = mapreduce(permutedims, vcat, coords_trace)
                push!(
                    ret,
                    CoordLog(coords_trace, log_date, note)
                )

                continue
            end

            # skip non coordinates
            if match(r"Coordinate:", l) |> isnothing
                continue
            end

            # parse coordinates
            coord = try
                match(r"\(.*\)", l).match |>
                (s -> split(s[2:end-1], ',')) .|>
                (x -> parse(Float64, x))
            catch e
                error("Failed to parse coordinate at line $(i)")
            end
            push!(coords_trace, coord)
        end
    end
    ret
end

function parse_log(filepaths::Vector{T}; interactive=false)::Vector{CoordLog} where {T <: AbstractString}
    map(filepaths) do filepath
        parse_log(filepath; interactive=interactive)
    end |> Iterators.flatten |> collect
end
CoordLog(
    [1.0 2.0 3.0; 4.0 5.0 6.0],
    Dates.now(),
    "a"
)
