true || include("src/CoordVisualize.jl")
true || using GLMakie
using CoordVisualize
using FileIO
using ColorSchemes
using ColorTypes

mappath = "map.png"
map = load(mappath)
map_height, map_width = size(map)

fig = Figure(; size = (1000, 700))
ax = Axis(
    fig[1:2, 1],
    limits = (
        -map_width ÷ 2 * 1.1,
        map_width ÷ 2 * 1.1,
        -map_height ÷ 2 * 1.1,
        map_height ÷ 2 * 1.1,
    ),
    aspect = DataAspect(),
)

# Options
options_width = 200
button_reset = Button(fig, label = "reset view")
toggle_inspector = Toggle(fig, active = false, tellwidth = false)
menu_lcolormapfunc =
    Menu(fig, options = ["log", "altitude", "date", "constant"], default = "log")
menu_mcolormapfunc =
    Menu(fig, options = ["log", "altitude", "date", "constant"], default = "log")
toggle_line = Toggle(fig, active = true, tellwidth = false)
toggle_marker = Toggle(fig, active = false, tellwidth = false)
slider_linewidth = Slider(fig, range = unique([1:1:5..., 5:2:15..., 15, 20:10:100...]))
slider_markersize = Slider(fig, range = unique([1:1:10..., 10:5:100...]), startvalue = 5)
# menu_linecolormap =
#     Menu(fig, options = string.(keys(ColorSchemes.colorschemes)), default = "viridis")
# menu_markercolormap =
#     Menu(fig, options = string.(keys(ColorSchemes.colorschemes)), default = "viridis")
textbox_linecolormap =
    Textbox(fig, validator = (s -> s in string.(keys(ColorSchemes.colorschemes))))
textbox_markercolormap =
    Textbox(fig, validator = (s -> s in string.(keys(ColorSchemes.colorschemes))))
textbox_linecolor = Textbox(fig, validator = (s -> begin
    try
        parse(Colorant, s)
    catch
        return false
    end
    return true
end), stored_string = "green")
lineconstcolor =
    @lift(ColorMapFuncs.Constant(parse(Colorant, $(textbox_linecolor.stored_string))))
textbox_markercolor = Textbox(fig, validator = (s -> begin
    try
        parse(Colorant, s)
    catch
        return false
    end
    return true
end), stored_string = "green")
markerconstcolor =
    @lift(ColorMapFuncs.Constant(parse(Colorant, $(textbox_markercolor.stored_string))))
line_options = grid!(
    [1, 1] => Label(fig, "color"),
    [1, 2:3] => menu_lcolormapfunc,
    [2, 1] => Label(fig, "show line"),
    [2, 2:3] => toggle_line,
    [3, 1] => Label(fig, "width"),
    [3, 2] => slider_linewidth,
    [3, 3] => Label(fig, @lift(string($(slider_linewidth.value)))),
    [4, 1] => Label(fig, "color scheme"),
    [4, 2:3] => textbox_linecolormap,
    [5, 1] => Label(fig, "color"),
    [5, 2:3] => textbox_linecolor,
    width = options_width,
)
marker_options = grid!(
    [1, 1] => Label(fig, "color"),
    [1, 2:3] => menu_mcolormapfunc,
    [2, 1] => Label(fig, "show marker"),
    [2, 2:3] => toggle_marker,
    [3, 1] => Label(fig, "size"),
    [3, 2] => slider_markersize,
    [3, 3] => Label(fig, @lift(string($(slider_markersize.value)))),
    [4, 1] => Label(fig, "color scheme"),
    [4, 2:3] => textbox_markercolormap,
    [5, 1] => Label(fig, "color"),
    [5, 2:3] => textbox_markercolor,
    width = options_width,
)
inspector_options = grid!(
    [1, 1] => Label(fig, "inspector"),
    [1, 2] => toggle_inspector,
    width = options_width,
)
fig[1:2, 3] = grid!(
    [0, :] => Label(fig, "Line", font = :bold),
    [1, :] => line_options,
    [2, :] => Label(fig, "Marker", font = :bold),
    [3, :] => marker_options,
    [4, :] => Label(fig, "Axis", font = :bold),
    [5, :] => inspector_options,
    [6, :] => button_reset,
    tellheight = false,
    width = options_width,
)

# tlog = vcat(CoordVisualize.parse_log.(["coord_log_5.txt", "coord_log_6.txt"])...)

# Main
heatmap!(
    ax,
    (1:map_width) .- map_width ÷ 2 .- 1,
    (1:map_height) .- map_height ÷ 2 .- 1,
    rotr90(map),
    inspectable = false,
)

tr2d = CoordVisualize.trace2ds!(
    ax,
    tlog,
    linewidth = slider_linewidth.value,
    markersize = slider_markersize.value,
)

# legend
cbl = Colorbar(
    fig,
    colormap = tr2d.linecolormap,
    ticks = tr2d.lcolorticks,
    # ticklabelrotation = π / 2,
    ticklabelsize = 10,
    label = menu_lcolormapfunc.selection,
    # vertical = false,
    # flipaxis = false,
)
cbm = Colorbar(
    fig,
    colormap = tr2d.markercolormap,
    ticks = tr2d.mcolorticks,
    # ticklabelrotation = π / 2,
    ticklabelsize = 10,
    label = menu_mcolormapfunc.selection,
)
fig[1:2, 2] = grid!(
    [0, 1] => Label(fig, "line", font = :bold),
    [1, 1] => cbl,
    [2, 1] => Label(fig, "marker", font = :bold),
    [3, 1] => cbm,
    tellheight = true,
)

inspector = DataInspector(tr2d)
inspector.attributes.enabled[] = false

on(menu_lcolormapfunc.selection) do s
    if s == "log"
        tr2d.lcolormapfunc[] = ColorMapFuncs.ColorMap()
    elseif s == "altitude"
        tr2d.lcolormapfunc[] = ColorMapFuncs.Altitude()
    elseif s == "date"
        tr2d.lcolormapfunc[] = ColorMapFuncs.Date()
    elseif s == "constant"
        tr2d.lcolormapfunc[] = lineconstcolor[]
    end
end
on(lineconstcolor) do c
    tr2d.lcolormapfunc[] = c
end
on(menu_mcolormapfunc.selection) do s
    if s == "log"
        tr2d.mcolormapfunc[] = ColorMapFuncs.ColorMap()
    elseif s == "altitude"
        tr2d.mcolormapfunc[] = ColorMapFuncs.Altitude()
    elseif s == "date"
        tr2d.mcolormapfunc[] = ColorMapFuncs.Date()
    elseif s == "constant"
        tr2d.mcolormapfunc[] = markerconstcolor[]
    end
end
on(markerconstcolor) do c
    tr2d.mcolormapfunc[] = c
end
on(button_reset.clicks) do n
    reset_limits!(ax)
    # slider_markersize.value[] = 5
    # slider_linewidth.value[] = 1
    # toggle_line.active[] = true
    # toggle_marker.active[] = false
end
on(textbox_linecolormap.stored_string) do s
    tr2d.linecolormap[] = ColorSchemes.colorschemes[Symbol(s)]
end
on(textbox_markercolormap.stored_string) do s
    tr2d.markercolormap[] = ColorSchemes.colorschemes[Symbol(s)]
end
on(toggle_inspector.active) do f
    inspector.attributes.enabled[] = f
end

connect!(tr2d.showline, toggle_line.active)
connect!(tr2d.showmarker, toggle_marker.active)

display(fig)
