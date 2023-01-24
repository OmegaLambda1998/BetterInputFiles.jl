using Documenter
push!(LOAD_PATH, "../src/")
using InputFiles

DocMeta.setdocmeta!(InputFiles, :DocTestSetup, :(using InputFiles); recursive=true)

makedocs(
    sitename="InputFiles Documentation",
    modules = [InputFiles, InputFiles.MacroModule, InputFiles.SetupModule, InputFiles.IOModule],
    pages = [
        "InputFiles" => "index.md",
        "Advanced Usage" => "advanced.md",
        "API" => "api.md"
    ],
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"],
    )
)

deploydocs(
    repo = "github.com/OmegaLambda1998/InputFiles.jl.git"
)
