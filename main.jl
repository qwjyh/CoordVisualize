using GLMakie
using ColorSchemes
using FileIO

function get_coord_traces()
    coords_traces = []
    coords_trace = []
    is_tracing = false
    for (i, l) in enumerate(readlines("coord_log.txt"))
        # skip logs not from coordinates
        if match(r"^\[TRACECOORDS\]", l) |> isnothing
            continue
        end
        if !is_tracing
            if match(r"Logging starting", l) |> !isnothing
                # @info "Logging started: $i"
                is_tracing = true
                empty!(coords_trace)
            end
        else
            if match(r"Logging stopping", l) |> !isnothing
                # @info "Logging stopped: $i"
                is_tracing = false
                push!(coords_traces, mapreduce(permutedims, vcat, coords_trace))
                continue
            end
            # skip non coordinates
            if match(r"Coordinate:", l) |> isnothing
                continue
            end
            coord = match(r"\(.*\)", l).match |>
                (s -> split(s[2:end-1], ',')) .|>
                (x -> parse(Float64, x))
            push!(coords_trace, coord)
            # @info length(coords_trace)
        end
    end
    return coords_traces
end

coords_traces = get_coord_traces()

coords = readchomp("coord_log.txt") |>
    (s -> split(s, '\n')) |>
    (vs -> filter(s -> match(r"^\[TRACECOORDS\]", s) |> !isnothing, vs)) |>
    (vs -> filter(s -> match(r"Coordinate:", s) |> !isnothing, vs)) .|>
    (s -> match(r"\(.*\)", s).match) .|>
    (s -> begin
        s[2:end-1] |>
        (s -> split(s, ',')) .|>
        (x -> parse(Float64, x))
    end) |>
    (x -> mapreduce(permutedims, vcat, x))


# fig = Figure()
# ax = Axis3(fig[1, 1])
# scatterlines!(
#     ax,
#     coords[:, 1],
#     - coords[:, 2],
#     coords[:, 3]
# )
# DataInspector(fig)
#
# fig


img = load("map.png")
yl, xl = size(img)
@assert xl % 2 == 0 && yl % 2 == 0
xmin, xmax = extrema([- xl ÷ 2, xl ÷ 2, floor(Int64, minimum(coords[:, 1])), ceil(Int64, maximum(coords[:, 1]))])
ymin, ymax = extrema([- yl ÷ 2, yl ÷ 2, floor(Int64, minimum(coords[:, 2])), ceil(Int64, maximum(coords[:, 2]))])
margin = 30
fig2 = Figure(
    # ; resolution = (xmax - xmin + 10margin + 50, ymax - ymin + 10margin)
)
fig = Figure()
hmin, hmax = coords_traces .|> (m -> m[:, 2]) |> Iterators.flatten |> extrema
hconvert(h) = (h - hmin) / (hmax - hmin)
color_v = ColorSchemes.colorschemes[:roma]
# ga = fig[1, 1] = GridLayout()
# gb = fig[1, 2] = GridLayout()
ax = Axis(
    fig2[1, 1],
    xlabel = "x",
    ylabel = "z",
    aspect = DataAspect(),
    alignmode = Outside(margin),
)
ax3 = Axis3(fig[1, 1], aspect = :data)
xs =  -xl ÷ 2:1:xl ÷ 2
ys =  -yl ÷ 2:1:yl ÷ 2
heatmap!(
    ax,
    xs, ys,
    rotr90(img),
    inspectable = false,
)
heatmap!(
    ax3,
    xs, ys,
    rotr90(img),
    inspectable = false,
)
# translate!(fig2.scene, -400, 0, 400)
for coords in coords_traces
    scatterlines!(
        ax,
        coords[:, 1],
        coords[:, 3],
        color = get(color_v, coords[:, 2], (hmin, hmax)),
        markersize = 3,
        label = "railway",
        # inspector_label = (plot, index, position) -> begin
        #     "($(coords[index, 1]), $(coords[index, 2]), $(coords[index, 3]))"
        # end,
        inspector_label = (_, _, _) -> "nothing",
    )
    scatterlines!(
        ax3,
        coords[:, 1],
        coords[:, 3],
        coords[:, 2],
    )
end
Colorbar(
    fig2[1, 2],
    colormap = :roma,
    limits = (hmin, hmax),
    label = "y",
    alignmode = Outside(margin),
)
[Box(
    fig2[1, i],
    color = :transparent,
    strokecolor = :red,
) for i in 1:2]
DataInspector(fig2)
fig2
