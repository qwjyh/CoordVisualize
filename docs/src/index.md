```@meta
CurrentModule = CoordVisualize
```

# CoordVisualize.jl

Documentation for CoordVisualize.jl

## Tutorial
Readers are expected to be familiar with basics of julia.

### Preparing
This will take a few minutes.

```juliarepl
julia> # type ]

(@v1.10) Pkg> activate .

(CoordVisualize) Pkg> instantiate
```

### Parse log
```juliarepl
julia> using CoordVisualize

julia> interactive_edit_log("coord_log_1.txt", "coord_log_2.txt")
...
  Follow the instruction
...
```

### CoordVisualize
Get map image file and place it as "map.png".

```juliarepl
julia> using GLMakie, CoordVisualize

julia> tlog = include("<exported log file>");

julia> include("<path to root>/interactive_viz.jl")
```

## Low level

### Log structure
CoordVisualize.jl treats coordination trace log with some additional information,
datetime when log was taken and supplemental note to annotate the log.
This set of log is represented by the type [`CoordLog`](@ref).

### Parsing Log
Use [`parse_log`](@ref) to parse log files generated with Tracecoords CSM mod.
Set the keyword argument `interactive` to `true` to supply notes interactively.
It automatically get datetime.
Notes can be also supplied in the following section.

### Editing
You sometimes want to split logs and to give more appropriate notes for each of them.
You can do this with [`split_log`](@ref) function.

You can also edit existing notes with [`assign_note!`](@ref).

### Exporting
Use [`export_log`](@ref) to export log to `io` or `file`.

### Importing
Do `using Dates` first and just `include("filename")` and it will return `Vector{CoordLog}`.
