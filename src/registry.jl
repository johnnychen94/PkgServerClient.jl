const registry = Dict{String, NamedTuple}(
    # in alphabetic order
    "ISCAS" => (;
        org="中国科学院软件研究所",
        url="https://mirror.iscas.ac.cn/julia"
    ),
    "BFSU" => (;
        org="北京外国语大学开源软件镜像站",
        url="https://mirrors.bfsu.edu.cn/julia",
        deprecated=true,
    ),
    "NJU" => (;
        org="南京大学开源镜像站",
        url="https://mirrors.nju.edu.cn/julia")
    ,
    "PKU" => (;
        org="北京大学开源镜像站",
        url="https://mirrors.pku.edu.cn/julia",
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
        url="https://mirrors.tuna.tsinghua.edu.cn/julia",
        deprecated=true,
    ),
    "USTC" => (;
        org="中国科学技术大学开源软件镜像",
        url="https://mirrors.ustc.edu.cn/julia"
    ),
)

function _registry_str()
    # always put "JuliaLang" to the first
    registry_str = join(["- `\"$k\"`: $(registry[k].org)\n" for k in sort(collect(keys(registry)))])
    registry["JuliaLang"] = (; org="The official Julia pkg server", url="https://pkg.julialang.org")
    registry_str = "- `\"JuliaLang\"`: The official Julia pkg server\n" * registry_str
end
const registry_str = _registry_str()
