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
            (1:heigh) .- heigh ÷ 2,
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

