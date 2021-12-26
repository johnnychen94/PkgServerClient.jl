# PkgServerClient

[![Build Status](https://github.com/johnnychen94/PkgServerClient.jl/workflows/CI/badge.svg)](https://github.com/johnnychen94/PkgServerClient.jl/actions)
[![Coverage](https://codecov.io/gh/johnnychen94/PkgServerClient.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/johnnychen94/PkgServerClient.jl)
[![中文README](https://img.shields.io/badge/README-%E4%B8%AD%E6%96%87-blue)](README_zh.md)

> Julia >= v"1.4" is required to use the Pkg server feature.

A list of 3rd-party Julia pkg/storage server mirror are provided in the [registry](src/registry.jl),
this package gives you a way to automatically switch to the nearest one in terms of RTT(round trip time).

In plain words, you could manually switch Julia pkg server by setting environment variable
`JULIA_PKG_SERVER`, and all that this package do is to set this variable automatically and smartly.

## Example

You only need to load this package in order to use it. Note that the environment variable `JULIA_PKG_SERVER`
is set after you load this package.

```julia
julia> versioninfo()
Julia Version 1.6.0
Commit f9720dc2eb (2021-03-24 12:55 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin19.6.0)
  CPU: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-11.0.1 (ORCJIT, skylake)

julia> using PkgServerClient

julia> versioninfo()
Julia Version 1.6.0
Commit f9720dc2eb (2021-03-24 12:55 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin19.6.0)
  CPU: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-11.0.1 (ORCJIT, skylake)
Environment:
  JULIA_PKG_SERVER = https://mirrors.sjtug.sjtu.edu.cn/julia
```

Note that if you already have `JULIA_PKG_SERVER` environment set, then loading this package is a
no-op; nothing will change.

You could optionally add the following line to `$JULIA_DEPOT_PATH/config/startup.jl` (by default it
is `~/.julia/config/startup.jl`) so that every time when you start Julia, it points you to the
nearest pkg server.

```julia
if VERSION >= v"1.4"
    try
        using PkgServerClient
    catch e
        @warn "error while importing PkgServerClient" e
    end
end
```

Also note that it is not guaranteed which `JULIA_PKG_SERVER` will be set when you load this package.
If you wish, you could manually call `PkgServerClient.generate_startup([server = <nearest-server>])`,
which will write the following code to your `startup.jl` file.

```julia
`ENV["JULIA_PKG_SERVER"] = <server-url>
```

For example:

```julia
julia> PkgServerClient.generate_startup("JuliaLang")
┌ Info: Update PkgServer
│   NewServer = "https://pkg.julialang.org"
│   OldServer = "https://mirrors.bfsu.edu.cn/julia"
└   ConfigFile = "/Users/jc/.julia/config/startup.jl"
```

### Using private pkg servers

The following startup script enables you to always use available private pkg servers set up in LAN
network while still falls back to public pkg servers when you leave the LAN network.

```julia
try
    import PkgServerClient
    # This is the server I set up in the school LAN network so it's not reachable outside
    PkgServerClient.registry["LFLab"] = (; org="LFLab, Math ECNU", url="https://mirrors.lflab.cn/julia")
    @async begin
        resp = PkgServerClient.registry_response_time()
        if !isinf(resp["LFLab"])
            PkgServerClient.set_mirror("LFLab")
        else
            # fallback to "nearest" public pkg servers
            PkgServerClient.set_mirror()
        end
    end
catch e
    @warn "error while importing PkgServerClient" e
end
```

### Get registry information

Furthermore, if you're interested, you could check the registry with `PkgServerClient.registry` and
`PkgServerClient.registry_response_time()`. As of the time of writing, here it's what I get in China:


```julia
julia> PkgServerClient.registry
Dict{String, NamedTuple{(:org, :url), Tuple{String, String}}} with 8 entries:
  "BFSU"      => (org = "北京外国语大学开源软件镜像站", url = "https://mirrors.bfsu.edu.cn/julia")
  "OpenTUNA"  => (org = "OpenTUNA开源镜像站 -- TUNA 协会", url = "https://opentuna.cn/julia")
  "SJTUG"     => (org = "上海交通大学Linux用户组 (SJTUG) 软件源镜像服务", url = "https://mirrors.sjtug.sjtu.edu.cn/julia")
  "USTC"      => (org = "中国科学技术大学开源软件镜像", url = "https://mirrors.ustc.edu.cn/julia")
  "SUSTech"   => (org = "南方科技大学开源镜像站", url = "http://mirrors.sustech.edu.cn/julia")
  "TUNA"      => (org = "清华大学开源软件镜像站 -- TUNA 协会", url = "https://mirrors.tuna.tsinghua.edu.cn/julia")
  "JuliaLang" => (org = "The official Julia pkg server", url = "https://pkg.julialang.org")
  "NJU"       => (org = "南京大学开源镜像站", url = "https://mirrors.nju.edu.cn/julia")

julia> PkgServerClient.registry_response_time()
Dict{String, Float64} with 8 entries:
  "BFSU"      => 0.0323085
  "OpenTUNA"  => 0.146376
  "SJTUG"     => 0.0093373
  "USTC"      => 0.230767
  "SUSTech"   => 0.269097
  "TUNA"      => 0.184747
  "JuliaLang" => Inf
  "NJU"       => 0.0445983
```

It might be outdated, but you get the idea.

## Adding new mirrors

Modify `registry.jl` and that's all!

## Acknowledgement

The mirror set functionality originally lived in [JuliaZH.jl](https://github.com/JuliaCN/JuliaZH.jl).
I added the auto-switch part and thus made it an independent package.
