using Documenter
using CoordVisualize

makedocs(
    sitename = "CoordVisualize",
    format = Documenter.HTML(),
    modules = [CoordVisualize],
    pages = [
        "Top" => "index.md",
        "API list" => "apis.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
