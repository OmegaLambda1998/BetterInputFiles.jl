using Documenter
push!(LOAD_PATH, "../src/")
using BetterInputFiles

DocMeta.setdocmeta!(BetterInputFiles, :DocTestSetup, :(using BetterInputFiles); recursive=true)

makedocs(
    sitename="BetterInputFiles Documentation",
    modules = [BetterInputFiles, BetterInputFiles.SetupModule, BetterInputFiles.IOModule],
    pages = [
        "BetterInputFiles" => "index.md",
        "Advanced Usage" => "advanced.md",
        "API" => "api.md"
    ],
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"],
    )
)

deploydocs(
    repo = "github.com/OmegaLambda1998/BetterInputFiles.jl.git"
)
