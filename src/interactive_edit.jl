using Statistics
using Dates
using Printf

"""
Interactively parse log files and edit the log.
"""
function iedit_log(filenames...; writetofile = true)
    printstyled(stdout, "[CoordLog Editor] \n", color = :blue, bold = true)
    logs = CoordLog[]
    printstyled(stdout, "loading log files\n", color = :blue)
    for file in filenames
        append!(logs, parse_log(file))
    end
    printstyled(stdout, "all files loaded\n", color = :blue)
    edited_logs = CoordLog{Float64}[]
    for (i, log) in enumerate(logs)
        printstyled(stdout, "LogEdit: editing log $(i) / $(length(logs))\n", color = :blue)
        printstyled(stdout, "summary\n", color = :cyan)
        println(
            stdout,
            """
              mean            : $(mean(eachrow(log.coords)) .|> round |> Tuple)
              start           : $(log.coords[1, :] .|> round |> Tuple)
              end             : $(log.coords[end, :] .|> round |> Tuple)
              datetime        : $(Dates.format(log.logdate, DateFormat("yyyy-mm-dd HH:MM:SS")))
              number of coords: $(size(log.coords)[1])
            """,
        )
        @label ask
        printstyled(stdout, "split log?(y/N): ", color = :green, italic = true)
        ans = readline(stdin)
        if ans == "y" || ans == "Y"
            while true
                maximum = size(log.coords)[1]
                printstyled(
                    stdout,
                    "split at where (1 to n, n to end), max = $(maximum): ",
                    color = :green,
                    italic = true,
                )
                at = try
                    parse(UInt64, readline(stdin))
                catch
                    printstyled("invalid input, please type number\n", color = :red)
                    continue
                end
                if at ≥ maximum
                    printstyled("too large number; max = $(maximum)\n", color = :red)
                    continue
                end
                if at == 0
                    printstyled("must be larger than 0\n", color = :red)
                    continue
                end
                print("""
                      summary of the first log:
                        mean  : $(mean(eachrow(log.coords)[1:at]) .|> round |> Tuple)
                        start : $(log.coords[1, :] .|> round |> Tuple)
                        end   : $(log.coords[at, :] .|> round |> Tuple)
                      """)
                printstyled("note for the first log: ", color = :green, italic = true)
                note_1 = readline(stdin)
                new_log, log = split_log(log, at, note_1, "")
                push!(edited_logs, new_log)
                print(
                    """
                    summary of the remaining log:
                      mean            : $(mean(eachrow(log.coords)) .|> round |> Tuple)
                      start           : $(log.coords[1, :] .|> round |> Tuple)
                      end             : $(log.coords[end, :] .|> round |> Tuple)
                      datetime        : $(Dates.format(log.logdate, DateFormat("yyyy-mm-dd HH:MM:SS")))
                      number of coords: $(size(log.coords)[1])
                    """,
                )
                @goto ask
            end
        elseif ans == "n" || ans == "N" || ans == ""
            printstyled("note for the log: ", color = :green, italic = true)
            note = readline()
            assign_note!(log, note)
            push!(edited_logs, log)
        else
            printstyled("invalid ans; type y or n\n", color = :red)
            @goto ask
        end
    end
    println()
    printstyled("Finish editing\n", color = :blue, bold = true)
    printstyled("number of logs: $(length(edited_logs))\n", color = :cyan)
    printstyled("summary: length, note\n", color = :cyan)
    len_ncoords = maximum(ndigits.(n_coords.(edited_logs)))
    for log in edited_logs
        println("  ", lpad(n_coords(log), len_ncoords), " ", log.note)
    end
    if writetofile
        printstyled("Writing to file\n", color = :blue, bold = true)
        printstyled("filename: ", color = :green, italic = true)
        filename = readline()
        if filename in readdir()
            printstyled("$(filename) already exists.", color = :magenta)
            printstyled("Are you sure to overwrite? (y/N)", color = :magenta, italic = true)
            ans = readline()
            if ans == "y" || ans == "Y"
            elseif ans == "n" || ans == "N" || ans == ""
                printstyled(
                    "Skip exporting to a file. Please export the returned log manually.\n",
                    color = :magenta,
                )
                @goto finish
            end
        end
        open(filename, "w") do f
            println(f, "using Dates")
            println(f, export_log(edited_logs))
        end
        printstyled("Exported log to the file: $(filename)\n", color = :blue)
    end
    @label finish
    printstyled("Edit completed.\n", color = :blue, bold = true)
    return edited_logs
end

"""
    isplit_log!(
        logs::AbstractVector{CoordLog{T}},
        logid::Integer,
        pointid::Integer,
    ) where {T}

Split the log. Supply notes interactively.
"""
function isplit_log!(
    logs::AbstractVector{CoordLog{T}},
    logid::Integer,
    pointid::Integer,
) where {T}
    1 ≤ logid ≤ length(logs) ||
        throw(ArgumentError("logid out of index: ¬ 1 ≤ $(logid) ≤ $(length(logid))"))
    if !(1 < pointid < n_coords(logs[logid]))
        throw(
            ArgumentError(
                "pointid($(pointid)) out of index: min=2, max=$(n_coords(logs[logid]) - 1)",
            ),
        )
    end

    log = popat!(logs, logid)
    printstyled("note for the first log: ", color = :green, italic = true)
    note_1 = readline()
    printstyled("note for the second log: ", color = :green, italic = true)
    note_2 = readline()
    new_logs = split_log(log, pointid, note_1, note_2)
    insert!(logs, logid, new_logs[1])
    insert!(logs, logid + 1, new_logs[2])
end

"""
    iedit_note!(logs::AbstractVector{CoordLog{T}}, logid::Integer) where {T}

Edit the note at `logid`. Supply new note interactively.
"""
function iedit_note!(logs::AbstractVector{CoordLog{T}}, logid::Integer) where {T}
    1 ≤ logid ≤ length(logs) ||
        throw(ArgumentError("logid out of index: ¬ 1 ≤ $(logid) ≤ $(length(logid))"))
    printstyled("new note for the log: ", color = :green, italic = true)
    note = readline()
    logs[logid].note = note
end

"""
    ijoin_logs!(logs::AbstractVector{CoordLog{T}}, logid1::Integer, logid2::Integer) where {T}

Join the logs at `logid1` and `logid2`. Supply new note interactively.
"""
function ijoin_logs!(logs::AbstractVector{CoordLog{T}}, logid1::Integer, logid2::Integer) where {T}
    1 ≤ logid1 ≤ length(logs) ||
        throw(ArgumentError("logid1 out of index: ¬ 1 ≤ $(logid1) ≤ $(length(logid1))"))
    1 ≤ logid2 ≤ length(logs) ||
        throw(ArgumentError("logid2 out of index: ¬ 1 ≤ $(logid2) ≤ $(length(logid2))"))
    logid1 == logid2 && throw(ArgumentError("logid1 and logid2 cannot be the same"))
    if logid1 > logid2
        logid1, logid2 = logid2, logid1
    end
    
    log_1 = popat!(logs, logid1)
    log_2 = popat!(logs, logid2 - 1)
    
    printstyled("note for the new log: ", color = :green, italic = true)
    note = readline()
    log = join_log(log_1, log_2, note)
    insert!(logs, logid1, log)
end
