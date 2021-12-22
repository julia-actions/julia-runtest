module Kwargs

import Pkg

include(joinpath(@__DIR__, "autodetect-dependabot.jl"))

function kwargs(; coverage::Bool,
                  force_latest_compatible_version::Union{Bool, Symbol},
                  julia_args::AbstractVector{<:AbstractString}=String[])
    if !(force_latest_compatible_version isa Bool) && (force_latest_compatible_version != :auto)
        throw(ArgumentError("Invalid value for force_latest_compatible_version: $(force_latest_compatible_version)"))
    end

    kwargs_dict = Dict{Symbol, Any}()
    kwargs_dict[:coverage] = coverage

    if VERSION >= v"1.6.0"
        kwargs_dict[:julia_args] = julia_args
    elseif julia_args == ["--check-bounds=yes"]
        # silently don't add this default julia_args value as < 1.6 doesn't support julia_args, but it's the default state
    else
        println("::warning::The Pkg.test bounds checking behavior cannot be changed before Julia 1.6. VERSION=$VERSION, julia_args=$julia_args")
    end

    if VERSION < v"1.7.0-" || !hasmethod(Pkg.Operations.test, Tuple{Pkg.Types.Context, Vector{Pkg.Types.PackageSpec}}, (:force_latest_compatible_version,))
        (force_latest_compatible_version != :auto) && @warn("The `force_latest_compatible_version` option requires at least Julia 1.7", VERSION, force_latest_compatible_version)
        return kwargs_dict
    end

    if force_latest_compatible_version == :auto
        is_dependabot_job = AutodetectDependabot.is_dependabot_job()
        is_dependabot_job && @info("This is a Dependabot/CompatHelper job, so `force_latest_compatible_version` has been set to `true`")
        kwargs_dict[:force_latest_compatible_version] = is_dependabot_job
    else
        kwargs_dict[:force_latest_compatible_version] = force_latest_compatible_version::Bool
    end

    return kwargs_dict
end

end # module
