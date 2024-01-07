using GLMakie
using ColorTypes
using ColorSchemes

"""
Predefined color map functions.

# Types

[`ColorMapFunc`](@ref)

# Interface

Define these methods for the ColorMapFunc.

    (AbstractVector{CoordLog}) -> Vector{∈ [0, 1]}, ticks
"""
module ColorMapFuncs

using ..CoordVisualize: CoordLog, n_coords
using ColorTypes
using Dates: DateTime, DateFormat, @dateformat_str, format
using Makie: wong_colors, Scene

"""
# Methods
    (f::ColorMapFunc)(cmap, logs)

Helper method.
"""
abstract type ColorMapFunc end

function (f::ColorMapFunc)(cmap, logs, n)
    steps, ticklabels = f(logs, n)
    ticks = collect(LinRange(0, 1, n))
    return get.(Ref(cmap), steps), (ticks, ticklabels)
end

"Use same color."
struct Constant <: ColorMapFunc
    color::Colorant
end

Constant(c::Symbol) = Constant(parse(Colorant, c))

function (c::Constant)(map, logs, n)
    # Iterators.repeated(c.color, length(logs))
    fill(c.color, sum(n_coords, logs)), ([], [])
end

"Use colormap."
struct ColorMap <: ColorMapFunc
    colormap::AbstractVector{<:Colorant}
end

ColorMap() = ColorMap(wong_colors())
ColorMap(cmap::Vector{Symbol}) = ColorMap(map(cmap) do s
    parse(Colorant, s)
end)
function ColorMap(scene::Scene)
    ColorMap(theme(scene, :linecolor))
end

function (cm::ColorMap)(map, logs, n)
    cm = Iterators.cycle(cm.colormap)
    nlog_s = Iterators.map(n_coords, logs)
    colors =
        Iterators.map(zip(cm, nlog_s)) do (color, count)
            Iterators.repeated(color, count)
        end |> Iterators.flatten |> collect
    return colors, ([], [])
end

"Color depending on log date."
struct Date <: ColorMapFunc end

function (::Date)(logs::AbstractVector{CoordLog{T}}, n) where {T}
    dformat = dateformat"yyyy-m-d"
    logdates::Vector{DateTime} = map(logs) do log
        fill(log.logdate, n_coords(log))
    end |> (v -> vcat(v...))
    fst, lst = extrema(logdates)
    normeddate = (logdates .- fst) ./ (lst - fst)
    diff = (lst - fst) / (n - 1)
    ticklabels = format.(fst:diff:lst, dformat)
    return normeddate, ticklabels
end

"Color depending on altitude."
struct Altitude <: ColorMapFunc end

function (f::Altitude)(logs::AbstractVector{CoordLog{T}}, n) where {T}
    altitudes = map(logs) do log
        Iterators.map(eachrow(log.coords)) do c
            c[2]
        end
    end |> Iterators.flatten |> collect
    low, high = extrema(altitudes)
    normedalt = (altitudes .- low) ./ (high - low)
    ticklabels = string.(round.(LinRange(low, high, n)))
    return normedalt, ticklabels
end

end # module ColorMapFunc

# TODO: alpha?
"""
    trace2ds(log::Vector{CoordLog})

# Arguments
TODO
"""
@recipe(Trace2Ds, log) do scene
    Attributes(;
        showmarker = false,
        marker = theme(scene, :marker),
        markercolormap = theme(scene, :colormap),
        markersize = theme(scene, :markersize),
        strokewidth = 0,
        showline = true,
        linecolormap = theme(scene, :colormap),
        linestyle = theme(scene, :linestyle),
        linewidth = theme(scene, :linewidth),
        inspectable = theme(scene, :inspectable),
        lcolormapfunc = ColorMapFuncs.ColorMap(), # or func like in ColorMapFunc
        mcolormapfunc = ColorMapFuncs.ColorMap(),
        lcolorticks = nothing,
        nlcolorticks = 5,
        mcolorticks = nothing,
        nmcolorticks = 5,
    )
end

function Makie.plot!(tr2d::Trace2Ds)
    # @info "logs" tr2d
    # @info "fieldnames" tr2d.log
    # @info "" theme(tr2d, :colormap)

    lcolormapfunc = tr2d.lcolormapfunc

    ntraces = length(tr2d.log[]) # number of CoordLog
    linesegs = Observable(Point2f[])
    points = Observable(Point2f[])
    altitudes = Observable(Float64[])
    point_ids = Observable(Tuple{Int64, Int64}[])
    notes = Observable(String[])
    if tr2d.markercolormap[] isa Symbol
        tr2d.markercolormap[] = getproperty(ColorSchemes, tr2d.markercolormap[])
    end
    markercolors = Observable(
        tr2d.mcolormapfunc[](tr2d.markercolormap[], tr2d.log[], tr2d.nmcolorticks[])[1],
    )
    mticks = tr2d.mcolorticks
    if tr2d.linecolormap[] isa Symbol
        tr2d.linecolormap[] = getproperty(ColorSchemes, tr2d.linecolormap[])
    end
    # @info "lcolormapfunc" lcolormapfunc
    linecolors =
        Observable(lcolormapfunc[](tr2d.linecolormap[], tr2d.log[], tr2d.nlcolorticks[])[1])
    lticks = tr2d.lcolorticks

    # helper function which mutates observables
    function update_plot(
        logs::AbstractVector{<:CoordLog{T}},
        lcolormap,
        mcolormap,
        lcolormapfunc, #::Union{Symbol, Tuple{Symbol, Symbol}},
        mcolormapfunc,
    ) where {T}
        @info "update_plot"
        markercolors[]
        linecolors[]
        # @info "logs on update_plot" logs
        # init
        empty!(linesegs[])
        empty!(points[])
        empty!(altitudes[])
        empty!(point_ids[])
        empty!(markercolors[])
        if linecolors[] isa AbstractVector
            empty!(linecolors[])
        else
            linecolors[] = []
        end

        # update
        colors_count = 1
        lcolors, lticks[] = lcolormapfunc(lcolormap, logs, tr2d.nlcolorticks[])
        mcolors, mticks[] = mcolormapfunc(mcolormap, logs, tr2d.nmcolorticks[])
        for (i, log) in enumerate(logs)
            first = true
            for (j, point) in enumerate(eachrow(log.coords))
                push!(linesegs[], Point2f(point[1], point[3]))
                push!(linesegs[], Point2f(point[1], point[3]))
                push!(points[], Point2f(point[1], point[3]))
                push!(altitudes[], point[2])
                push!(point_ids[], (i, j))
                push!(linecolors[], lcolors[colors_count])
                push!(linecolors[], lcolors[colors_count])
                push!(markercolors[], mcolors[colors_count])
                colors_count += 1

                # # marker
                # if !isnothing(mcolormapfunc)
                #     push!(markercolors[], mcolormapfunc(logs)[i])
                # end

                if first
                    pop!(linesegs[])
                    pop!(linecolors[])
                    first = false
                else
                    # # colors
                    # if !isnothing(lcolormapfunc)
                    #     push!(linecolors[], lcolormapfunc(logs)[i])
                    # end
                end
            end
            pop!(linesegs[])
            pop!(linecolors[])
            push!(notes[], log.note)
        end

        markercolors[] = markercolors[]
        linecolors[] = linecolors[]
    end

    Makie.Observables.onany(
        update_plot,
        tr2d.log,
        tr2d.linecolormap,
        tr2d.markercolormap,
        lcolormapfunc,
        tr2d.mcolormapfunc,
    )

    # init
    update_plot(
        tr2d.log[],
        tr2d.linecolormap[],
        tr2d.markercolormap[],
        lcolormapfunc[],
        tr2d.mcolormapfunc[],
    )

    linesegments!(
        tr2d,
        linesegs,
        color = linecolors,
        linewidth = tr2d.linewidth,
        linestyle = tr2d.linestyle,
        visible = tr2d.showline,
        # inspector_label = (self, i, pos) -> 
    )
    scatter!(
        tr2d,
        points,
        color = markercolors,
        markersize = tr2d.markersize,
        strokewidth = tr2d.strokewidth,
        visible = tr2d.showmarker,
        inspector_label = (self, i, pos) -> begin
            logid, pointid = point_ids[][i]
            """
            log: $(logid), point: $(pointid)
            x: $(lpad(round(pos[1], digits = 1), 7))
            y: $(lpad(round(altitudes[][i], digits = 1), 7))
            z: $(lpad(round(pos[2], digits = 1), 7))
            $(tr2d.log[][logid].note)
            """
        end,
    )
    # @info "dump" dump(tr2d, maxdepth = 1)
    # @info "attributes" dump(tr2d.attributes, maxdepth = 3)

    tr2d
end
