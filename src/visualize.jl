using GLMakie
using ColorTypes
using ColorSchemes
using FileIO

function _plot_map!(ax, mappath::AbstractString)
    map = load(mappath)
    let
        heigh, width = size(map)
        heatmap!(
            ax,
            (1:width) .- width ÷ 2,
            (1:heigh) .- width ÷ 2,
            rotr90(map),
            inspectable = false,
        )
    end
end

function view_with_map(log::CoordLog; map = "map.png")
    fig = Figure()
    ax = Axis(fig[1, 1], aspect = AxisAspect(1))
    _plot_map!(ax, map)

    return fig
end

"""
Predefined color map functions.

# Interface
    (map, AbstractVector{CoordLog}) -> Vector{<: Colorant}
"""
module ColorMapFunc

using ..CoordVisualize: CoordLog, n_coords
using ColorTypes
using Dates: DateTime
using Makie: wong_colors, Scene

"Use same color."
struct Constant
    color::Colorant
end

Constant(c::Symbol) = Constant(parse(Colorant, c))

function (c::Constant)(map, logs)
    # Iterators.repeated(c.color, length(logs))
    fill(c.color, sum(n_coords, logs))
end

"Use colormap."
struct ColorMap
    colormap::AbstractVector{<:Colorant}
end

ColorMap() = ColorMap(wong_colors())
ColorMap(cmap::Vector{Symbol}) = ColorMap(map(cmap) do s
    parse(Colorant, s)
end)
function ColorMap(scene::Scene)
    ColorMap(theme(scene, :linecolor))
end

function (cm::ColorMap)(map, logs)
    cm = Iterators.cycle(cm.colormap)
    nlog_s = Iterators.map(n_coords, logs)
    Iterators.map(zip(cm, nlog_s)) do (color, count)
        Iterators.repeated(color, count)
    end |> Iterators.flatten |> collect
end

"Color depending on log date."
function date(cmap, logs::AbstractVector{CoordLog})
    logdates::Vector{DateTime} = map(logs) do log
        fill(log.logdate, n_coords(log))
    end |> (v -> vcat(v...))
    lst, fst = extrema(logdates)
    normeddate = (logdates .- lst) ./ (fst - lst)
    return get.(Ref(cmap), normeddate)
end

"Color depending on altitude."
function altitude(cmap, logs::AbstractVector{CoordLog})
    altitudes = map(logs) do log
        map(eachrow(log.coords)) do c
            c[2]
        end
    end |> Iterators.flatten |> collect
    low, high = extrema(altitudes)
    normedalt = (altitudes .- low) ./ (high - low)
    return get.(Ref(cmap), normedalt)
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
        marker = theme(scene, :marker),
        markercolormap = theme(scene, :colormap),
        markersize = theme(scene, :markersize),
        strokecolor = theme(scene, :strokecolor),
        strokewidth = theme(scene, :strokewidth),
        linecolormap = theme(scene, :colormap),
        linestyle = theme(scene, :linestyle),
        linewidth = theme(scene, :linewidth),
        inspectable = theme(scene, :inspectable),
        lcolormapfunc = ColorMapFunc.ColorMap(), # or func like in ColorMapFunc
        mcolormapfunc = ColorMapFunc.ColorMap(),
    )
end

function Makie.plot!(tr2d::Trace2Ds)
    # @info "logs" tr2d
    # @info "fieldnames" tr2d.log
    # @info "" theme(tr2d, :colormap)

    lcolormapfunc = tr2d.lcolormapfunc

    ntraces = length(tr2d.log[]) # number of CoordLog
    linesegs = Observable(Point2f[])
    notes = Observable(String[])
    if tr2d.markercolormap[] isa Symbol
        tr2d.markercolormap[] = getproperty(ColorSchemes, tr2d.markercolormap[])
    end
    markercolors = Observable(tr2d.mcolormapfunc[](tr2d.markercolormap[], tr2d.log[]))
    if tr2d.linecolormap[] isa Symbol
        tr2d.linecolormap[] = getproperty(ColorSchemes, tr2d.linecolormap[])
    end
    # @info "lcolormapfunc" lcolormapfunc
    linecolors = Observable(lcolormapfunc[](tr2d.linecolormap[], tr2d.log[]))
    on(linecolors) do lc
        @info "linecolors update"
    end
    @info "linecolors" linecolors

    # helper function which mutates observables
    function update_plot(
        logs::AbstractVector{<:CoordLog},
        lcolormap,
        mcolormap,
        lcolormapfunc, #::Union{Symbol, Tuple{Symbol, Symbol}},
        mcolormapfunc,
    )
        @info "update_plot"
        linecolors[]
        # @info "logs on update_plot" logs
        # init
        empty!(linesegs[])
        if !isnothing(mcolormapfunc)
            # if markercolors[] isa AbstractVector
            #     empty!(markercolors[])
            # else
            #     markercolors[] = []
            # end
            markercolors[] = mcolormapfunc(mcolormap, logs)
        end
        if linecolors[] isa AbstractVector
            empty!(linecolors[])
        else
            linecolors[] = []
        end

        # update
        linecolors_count = 1
        for (i, log) in enumerate(logs)
            first = true
            for point in eachrow(log.coords)
                push!(linesegs[], Point2f(point[1], point[3]))
                push!(linesegs[], Point2f(point[1], point[3]))
                push!(linecolors[], lcolormapfunc(lcolormap, logs)[linecolors_count])
                push!(linecolors[], lcolormapfunc(lcolormap, logs)[linecolors_count])
                linecolors_count += 1

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
    @info "tr2d" lcolormapfunc

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
    )
    # @info "dump" dump(tr2d, maxdepth = 1)
    # @info "attributes" dump(tr2d.attributes, maxdepth = 3)

    tr2d
end
