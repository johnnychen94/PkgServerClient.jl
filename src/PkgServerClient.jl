module PkgServerClient

using Downloads
include("registry.jl")

# This get updated once during module initialization: `__init__`.
# To avoid unnecessary delay due to network check, only explicit `registry_response_time` call
# updates it.
const _registry_response_time = Dict(k => Inf for k in keys(registry))
"""
    registry_response_time(; timeout=1)::Dict{String, Float64}

Query and return the registry response time. If any of the HEAD request exceeds the timeout,
the response time is set to `Inf`.
"""
function registry_response_time(; timeout=1)
    function response_time(url, timeout)
        try
            return @elapsed Downloads.request(url*"/registries",
                method="HEAD", timeout=timeout, throw=true)
        catch err
            return Inf
        end
    end

    # TODO:
    # Because some mirror server might fail to response, so it's almost certainly that calling this function
    # takes `timeout` seconds to execute. An improvement is to early exit when there're enough response counts
    # from the registry.
    @sync for (k, v) in registry
        @async _registry_response_time[k] = response_time(v.url, timeout)
    end

    # When all fails to response in a very limited `timeout` time, set the default to "JuliaLang"
    # with a convenient lie.
    if all(values(_registry_response_time) .== timeout)
        _registry_response_time["JuliaLang"] = 0
    end
    return _registry_response_time
end

"""
    get_fasted_mirror()

Directly return the codename for the mirror with lowest response time.

!!! note
    This function only query a cached mirror response time, that is, it doesn't send actual HEAD
    request to the mirror server. If you want to update the cached value, you can explicitly call
    `registry_response_time()`
"""
get_fasted_mirror() = first(sort(collect(_registry_response_time), by=item->item[2]))[1]

"""
    set_mirror([server])

Set current Pkg server to `server`. The available upstreams are:

$(registry_str)

By default, it will use the one with lowest response time.
"""
function set_mirror(server::String = get_fasted_mirror())
    ENV["JULIA_PKG_SERVER"] = registry[server].url
    return nothing
end

const regex_PKG_SERVER = r"^\s*[^#]*\s*(ENV\[\"JULIA_PKG_SERVER\"\]\s*=\s*)\"([\w\.:\/]*)\""

"""
    generate_startup(server)

Hardcode the following line into `startup.jl` file:

```julia
ENV["JULIA_PKG_SERVER"] = <mirror-url>
```

where `mirror-url` is the url to upstream `server`. By default, it will use
the one with lowest response time.
"""
function generate_startup(server::String = get_fasted_mirror())
    # Manually update the response time before doing this.
    registry_response_time()

    default_dot_julia = first(DEPOT_PATH)
    config_path = joinpath(default_dot_julia, "config")
    if !ispath(config_path)
        mkpath(config_path)
    end

    startup_path = joinpath(config_path, "startup.jl")
    if ispath(startup_path)
        startup_lines = readlines(startup_path)
    else
        startup_lines = String[]
    end

    new_upstream = registry[server].url
    new_line = "ENV[\"JULIA_PKG_SERVER\"] = \"$(new_upstream)\""
    
    pkg_matches = map(x->match(regex_PKG_SERVER, x), startup_lines)
    pkg_indices = findall(x->!isnothing(x), pkg_matches)
    if isempty(pkg_indices)
        @info "添加 PkgServer" 服务器地址=new_upstream 配置文件=startup_path
        append!(startup_lines, ["", "# 以下这一行由 PkgServerClient 自动生成", new_line, ""])
    else
        # only modify the last match
        idx = last(pkg_indices)
        old_upstream = pkg_matches[idx].captures[2]

        is_upstream_unchanged = occursin(new_upstream, old_upstream) || occursin(old_upstream, new_upstream)
        if !is_upstream_unchanged
            @info "更新 PkgServer" 新服务器地址=new_upstream 原服务器地址=old_upstream 配置文件=startup_path
            startup_lines[idx] = new_line
        end
    end

    write(startup_path, join(startup_lines, "\n"))
    return
end

function __init__()
    function _auto_switch()
        registry_response_time()
        mirror_node = get_fasted_mirror()
        set_mirror(mirror_node)
    end

    # In REPL mode a little bit delay is allowed
    if isinteractive()
        @async _auto_switch()
    else
        _auto_switch()
    end
end

end
