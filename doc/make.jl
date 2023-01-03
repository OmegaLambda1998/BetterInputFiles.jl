using Documenter
using OLUtils

DocMeta.setdocmeta!(OLUtils, :DocTestSetup, :(using OLUtils); recursive=true)

makedocs(
    sitename="OLUtils Documentation",
    modules = [OLUtils, OLUtils.SetupModule],
    pages = [
        "OLUtils" => "index.md",
        "Setup functions" => "setup.md",
    ],
    format = Documenter.HTML(
        prettyurls = false,
        assets = ["assets/favicon.ico"],
    )
)

deploydocs(
    rep = "github.com/OmegaLambda1998/OLUtils.git"
)