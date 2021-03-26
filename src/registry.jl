const registry = Dict{String, NamedTuple{(:org, :url), Tuple{String, String}}}(
    # in alphabetic order
    "BFSU" => (;
        org="北京外国语大学开源软件镜像站",
        url="https://mirrors.bfsu.edu.cn/julia"
    ),
    "NJU" => (;
        org="南京大学开源镜像站",
        url="https://mirrors.nju.edu.cn/julia")
    ,
    "OpenTUNA" => (;
        org="OpenTUNA开源镜像站 -- TUNA 协会",
        url="https://opentuna.cn/julia"
    ),
    "SJTUG" => (;
        org="上海交通大学Linux用户组 (SJTUG) 软件源镜像服务",
        url="https://mirrors.sjtug.sjtu.edu.cn/julia"
    ),
    "SUSTech" => (;
        org="南方科技大学开源镜像站",
        url="http://mirrors.sustech.edu.cn/julia"
    ),
    "TUNA" => (;
        org="清华大学开源软件镜像站 -- TUNA 协会",
        url="https://mirrors.tuna.tsinghua.edu.cn/julia"
    ),
    "USTC" => (;
        org="中国科学技术大学开源软件镜像",
        url="https://mirrors.ustc.edu.cn/julia"
    ),
)

# always put "JuliaLang" to the first
registry_str = join(["- `\"$k\"`: $(registry[k].org)\n" for k in sort(collect(keys(registry)))])
registry["JuliaLang"] = (; org="The official Julia pkg server", url="https://pkg.julialang.org")
registry_str = "- `\"JuliaLang\"`: The official Julia pkg server\n" * registry_str
