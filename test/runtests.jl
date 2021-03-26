using Test

ENV["JULIA_PKG_SERVER"] = ""
using PkgServerClient
using PkgServerClient: registry, registry_response_time

@testset "PkgServerClient.jl" begin
    @test !isempty(ENV["JULIA_PKG_SERVER"])


    @test all(keys(registry)) do k
        PkgServerClient.set_mirror(k)
        ENV["JULIA_PKG_SERVER"] == registry[k].url
    end

    println("Reigstry response time:")
    foreach(println, registry_response_time())

    # make sure the fallback "JuliaLang" is used when network issue happens
    @test registry_response_time(timeout=0.001)["JuliaLang"] == 0
end
