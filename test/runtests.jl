using Test

ENV["JULIA_PKG_SERVER"] = ""
using PkgServerClient
using PkgServerClient: registry

@testset "PkgServerClient.jl" begin
    @test !isempty(ENV["JULIA_PKG_SERVER"])


    @test all(keys(registry)) do k
        PkgServerClient.set_mirror(k)
        ENV["JULIA_PKG_SERVER"] == registry[k].url
    end

    println("Reigstry response time:")
    foreach(println, PkgServerClient.registry_response_time())
end
