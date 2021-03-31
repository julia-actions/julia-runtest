module Kwargs

include(joinpath(@__DIR__, "autodetect-dependabot.jl"))

function kwargs(; coverage::Bool,
                  force_latest_compatible_version::Union{Bool, Symbol})
    is_dependabot_job = AutodetectDependabot.is_dependabot_job()
    kwargs_dict = Dict{Symbol, Any}()
    kwargs_dict[:coverage] = coverage

    if VERSION >= v"1.7.0-" # excludes 1.6, includes 1.7-DEV, includes 1.7
        if force_latest_compatible_version isa Bool
            kwargs_dict[:force_latest_compatible_version] = force_latest_compatible_version
        elseif force_latest_compatible_version == :auto
            is_dependabot_job && @info("This is a Dependabot/CompatHelper job, so `force_latest_compatible_version` has been set to `true`")
            kwargs_dict[:force_latest_compatible_version] = is_dependabot_job
        else
            throw(ArgumentError("Invalid value for force_latest_compatible_version: $(force_latest_compatible_version)"))
        end
    else
        if force_latest_compatible_version != :auto
            @warn("The `force_latest_compatible_version` option requires at least Julia 1.7", VERSION, force_latest_compatible_version)
        end
    end
    return kwargs_dict
end

end # module
