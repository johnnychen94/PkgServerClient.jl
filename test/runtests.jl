using Test

ENV["JULIA_PKG_SERVER"] = ""
using PkgServerClient
using PkgServerClient: registry, registry_response_time

function query_upstream(startup_path)
    if ispath(startup_path)
        startup_lines = readlines(startup_path)
    else
        startup_lines = String[]
    end

    pkg_matches = map(x->match(PkgServerClient.regex_PKG_SERVER, x), startup_lines)
    pkg_indices = findall(x->!isnothing(x), pkg_matches)

    if isempty(pkg_indices)
        return ""
    else
        # only last match counts
        return pkg_matches[last(pkg_indices)].captures[2]
    end
end

@testset "PkgServerClient.jl" begin
    @test !isempty(ENV["JULIA_PKG_SERVER"])


    @test all(keys(registry)) do k
        if get(registry[k], :deprecated, false)
            return true
        end

        PkgServerClient.set_mirror(k)
        ENV["JULIA_PKG_SERVER"] == registry[k].url
    end

    println("Reigstry response time:")
    foreach(println, registry_response_time())

    # make sure the fallback "JuliaLang" is used when network issue happens
    @test registry_response_time(timeout=0.001)["JuliaLang"] == 0

    @test_throws ArgumentError PkgServerClient.set_mirror("UNKNOWN_SERVER_ABCDE")
    @test_throws ArgumentError PkgServerClient.generate_startup("UNKNOWN_SERVER_ABCDE")

    # check `generate_startup`
    mktempdir() do tmp
        pushfirst!(DEPOT_PATH, tmp)
        default_dot_julia = first(DEPOT_PATH)
        config_path = joinpath(default_dot_julia, "config")
        if !ispath(config_path)
            mkpath(config_path)
        end

        startup_path = joinpath(config_path, "startup.jl")
        @test !isfile(startup_path)
        PkgServerClient.generate_startup()
        @test !isempty(query_upstream(startup_path))
        PkgServerClient.generate_startup("PKU")
        @test query_upstream(startup_path) == "https://mirrors.pku.edu.cn/julia"
    end
end
