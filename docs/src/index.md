```@meta
CurrentModule = CoordVisualize
```

# CoordVisualize.jl

Documentation for CoordVisualize.jl

## Tutorial
Readers are expected to be familiar with basics of julia.

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

