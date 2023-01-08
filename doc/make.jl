using Documenter
using InputFiles

DocMeta.setdocmeta!(InputFiles, :DocTestSetup, :(using InputFiles); recursive=true)

makedocs(
    sitename="InputFiles Documentation",
    modules = [InputFiles, InputFiles.SetupModule],
    pages = [
        "InputFiles" => "index.md",
        "Setup functions" => "setup.md",
    ],
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"],
    )
)

deploydocs(
    repo = "github.com/OmegaLambda1998/InputFiles.jl.git"
)
