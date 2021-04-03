module Kwargs

include(joinpath(@__DIR__, "autodetect-dependabot.jl"))

function kwargs()
    coverage_env                            = ENV["INPUT_COVERAGE"]
    force_latest_compatible_version_env     = ENV["INPUT_FORCE_LATEST_COMPATIBLE_VERSION"]
    additional_keyword_arguments_env        = ENV["INPUT_ADDITIONAL_KEYWORD_ARGUMENTS"]

    coverage = parse(Bool, coverage_env)::Bool

    _force_latest_compatible_version = tryparse(Bool, force_latest_compatible_version_env)
    if _force_latest_compatible_version isa Bool
        force_latest_compatible_version = _force_latest_compatible_version::Bool
    else
        force_latest_compatible_version = Symbol(strip(force_latest_compatible_version_env))::Symbol
    end

    if !(force_latest_compatible_version isa Bool) && (force_latest_compatible_version != :auto)
        throw(ArgumentError("Invalid value for force_latest_compatible_version: $(force_latest_compatible_version)"))
    end

    @info "" coverage typeof(coverage)                                                 # TODO: remove this debugging line
    @info "" force_latest_compatible typeof(force_latest_compatible)                   # TODO: remove this debugging line
    @info "" additional_keyword_arguments_env typeof(additional_keyword_arguments_env) # TODO: remove this debugging line

    kwargs_dict = Dict{Symbol, Any}()
    kwargs_dict[:coverage] = coverage

    if VERSION < v"1.7.0-"
        (force_latest_compatible_version != :auto) && @warn("The `force_latest_compatible_version` option requires at least Julia 1.7", VERSION, force_latest_compatible_version)
        return kwargs_dict
    else
        if force_latest_compatible_version == :auto
            is_dependabot_job = AutodetectDependabot.is_dependabot_job()
            is_dependabot_job && @info("This is a Dependabot/CompatHelper job, so `force_latest_compatible_version` has been set to `true`")
            kwargs_dict[:force_latest_compatible_version] = is_dependabot_job
        else
            kwargs_dict[:force_latest_compatible_version] = force_latest_compatible_version::Bool
        end
    end

    for (k, v) in parse_additional_keyword_arguments(additional_keyword_arguments_env)
        if haskey(kwargs_dict)
            throw(ArgumentError("Duplicate keyword: $(name)"))
        end
        kwargs_dict[k] = v
    end

    return kwargs_dict
end

# example usage:
# ```yaml
# steps:
#   - uses: julia-actions/julia-runtest@v1
#     with:
#       additional_keyword_arguments: 'foo = true, bar = "hello", baz = world'
# ```
function parse_additional_keyword_arguments(additional_keyword_arguments_string::String)
    items = strip.(split(additional_keyword_arguments_string, ','))
    additional_keyword_arguments = Dict{Symbol, Any}()
    for item in items
        if !isempty(item)
            m = match(r"^([\w]*?)[\s]*?=[\s]*?([\w\"]*?)$", item)
            if m isa Nothing
                throw(ArgumentError("Invalid syntax: $(item)"))
            end
            kwname = Symbol(strip(m[1]))
            kwvalue = Meta.parse(strip(m[2]))
            if haskey(additional_keyword_arguments, kwname)
                throw(ArgumentError("Duplicate keyword: $(kwname)"))
            end
            @info "Adding keyword argument" kwname kwvalue typeof(kwvalue)
            additional_keyword_arguments[kwname] = kwvalue
        end
    end
    return additional_keyword_arguments
end

function _unquote_symbol(x::QuoteNode)::Symbol
    value = x.value
    if !(value isa Symbol)
        throw(ArgumentError("$(value) is not a Symbol"))
    end
    return value::Symbol
end

end # module
