using Pkg

function general_registry_location()
    general_registry_dir = joinpath(DEPOT_PATH[1], "registries", "General")
    registry_toml_file = joinpath(general_registry_dir, "Registry.toml")
    return general_registry_dir, registry_toml_file
end

function general_registry_exists()
    general_registry_dir, registry_toml_file = general_registry_location()
    if !isdir(general_registry_dir)
        return false
    elseif !isfile(registry_toml_file)
        return false
    else
        return true
    end
end

function add_general_registry()
    @info("Attempting to clone the General registry")
    general_registry_dir, registry_toml_file = general_registry_location()
    rm(general_registry_dir; force = true, recursive = true)
    Pkg.Registry.add("General")
    isfile(registry_toml_file) || throw(ErrorException("the Registry.toml file does not exist"))
    return nothing
end

function main(; n = 10, max_delay = 120)
    if VERSION >= v"1.5-"
        if !general_registry_exists()
            delays = ExponentialBackOff(; n = n, max_delay = max_delay)
            try
                retry(add_general_registry; delays = delays)()
                @info("Successfully added the General registry")
            catch ex
                msg = "I was unable to added the General registry. However, the build will continue."
                @error(msg, exception=(ex,catch_backtrace()))
            end
        else
            @info("The General registry already exists locally")
        end
    end
    return nothing
end

main()
