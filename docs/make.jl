using PkgServerClient
using Documenter

DocMeta.setdocmeta!(PkgServerClient, :DocTestSetup, :(using PkgServerClient); recursive=true)

makedocs(;
    modules=[PkgServerClient],
    authors="Johnny Chen <johnnychen94@hotmail.com>",
    repo="https://github.com/johnnychen94/PkgServerClient.jl/blob/{commit}{path}#{line}",
    sitename="PkgServerClient.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://johnnychen94.github.io/PkgServerClient.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/johnnychen94/PkgServerClient.jl",
)
