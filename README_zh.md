# PkgServerClient

[![Build Status](https://github.com/johnnychen94/PkgServerClient.jl/workflows/CI/badge.svg)](https://github.com/johnnychen94/PkgServerClient.jl/actions)
[![Coverage](https://codecov.io/gh/johnnychen94/PkgServerClient.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/johnnychen94/PkgServerClient.jl)
[![英文README](https://img.shields.io/badge/README-%E4%B8%AD%E6%96%87-blue)](README.md)

> 需要 1.4 以后的 Julia 版本

[registry](src/registry.jl) 里面记录了一些 Julia 包服务器及镜像站的信息， `PkgServerClient.jl` 会根据延迟将你自动导向最近的镜像站。

## 例子

你需要做的仅仅只是加载这个包， 通过 `versioninfo()` 可以看到， 在加载完成后添加了一条 `JULIA_PKG_SERVER` 这个记录。

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

需要注意的是， 如果之前已经在设置过 `JULIA_PKG_SERVER` 这一环境变量， 则加载这个包的时候什么也不会发生： 
你依然还是在使用你之前手动设置的包服务器作为上游。

你可以考虑将下面的代码加入到你的 `startup.jl` 文件里(默认情况下是 `~/.julia/config/startup.jl`)，
这里面的代码会在每一次 Julia 启动的时候被调用， 从而实现自动切换镜像的目的：

```julia
if VERSION >= v"1.4"
    try
        using PkgServerClient
    catch e
        @warn "error while importing PkgServerClient" e
    end
end
```

因为这种切换是自动的， 所以根据网络情况的不同， 每次使用的镜像也是不一样的。 如果你需要在一定程度上固定的镜像站作为上游
的话， 你可以直接使用 `generate_startup([server = <nearest-server>])`， 它会自动将下述代码插入到 `startup.jl`
里面：

```julia
`ENV["JULIA_PKG_SERVER"] = <server-url>
```

例如：

```julia
julia> PkgServerClient.generate_startup("JuliaLang")
┌ Info: Update PkgServer
│   NewServer = "https://pkg.julialang.org"
│   OldServer = "https://mirrors.bfsu.edu.cn/julia"
└   ConfigFile = "/Users/jc/.julia/config/startup.jl"
```

### 使用内网 Pkg server

有些时候（比如说在学校或者公司）会搭建局域网下的 Pkg Server， 下面这个 `startup.jl` 脚本会自动检测并自动接入到
内网服务器。

```julia
try
    import PkgServerClient
    # 这是我在 ECNU 内部搭建的一个镜像服务器所以在外面无法访问
    PkgServerClient.registry["LFLab"] = (; org="LFLab, Math ECNU", url="https://mirrors.lflab.cn/julia")
    @async begin
        resp = PkgServerClient.registry_response_time()
        if !isinf(resp["LFLab"])
            PkgServerClient.set_mirror("LFLab")
        else
            # 如果 LFLab 无法访问的话， 则使用 “最近” 的公开服务器
            PkgServerClient.set_mirror()
        end
    end
catch e
    @warn "error while importing PkgServerClient" e
end
```

## 其他

如果感兴趣的话， 你也可以通过 `PkgServerClient.registry` 和 `PkgServerClient.registry_response_time()` 来
查询一些服务器信息。 例如， 下面是我写这个文档时的执行结果：

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

# 添加新的镜像站

修改 `registry.jl` 文件即可。
