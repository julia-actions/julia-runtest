import Pkg

# JULIA_PKG_USE_CLI_GIT is already set by the action for Julia >= 1.7
# Just provide a notice if it's set but Julia version doesn't support it
if VERSION < v"1.7-" && haskey(ENV, "JULIA_PKG_USE_CLI_GIT") && parse(Bool, ENV["JULIA_PKG_USE_CLI_GIT"]) == true
    printstyled("::notice::JULIA_PKG_USE_CLI_GIT requires Julia >= 1.7. Using default LibGit2 git-interface instead!\n"; color = :yellow)
end

include("kwargs.jl")
kwargs = Kwargs.kwargs(; coverage=ENV["COVERAGE"],
                         force_latest_compatible_version=ENV["FORCE_LATEST_COMPATIBLE_VERSION"],
                         allow_reresolve=ENV["ALLOW_RERESOLVE"],
                         julia_args=[string("--check-bounds=", ENV["CHECK_BOUNDS"]),
                                     string("--compiled-modules=", ENV["COMPILED_MODULES"]),
                                     # Needs to be done via `julia_args` to ensure `depwarn: no` is respected:
                                     # https://github.com/JuliaLang/Pkg.jl/pull/1763#discussion_r406819660
                                     string("--depwarn=", ENV["DEPWARN"]),],
                         test_args=ARGS,
                         )

kwargs_reprs = map(kv -> string(kv[1], "=", repr(kv[2])), collect(kwargs))
kwargs_repr = join(kwargs_reprs, ", ")

print("""
│
│ To reproduce this CI run locally run the following from the same repository state on julia version $VERSION:
│
│ `import Pkg; Pkg.test(;$kwargs_repr)`
│
""")

if parse(Bool, ENV["ANNOTATE"]) && v"1.8pre" < VERSION < v"1.9.0-beta3"
    push!(LOAD_PATH, "@tests-logger-env") # access dependencies
    using GitHubActions, Logging
    global_logger(GitHubActionsLogger())
    include("test_logger.jl")
    pop!(LOAD_PATH)
    try
        TestLogger.test(; kwargs...)
    catch e
        if e isa Pkg.Types.PkgError
            # don't show the stacktrace of the test harness because it's not useful
            showerror(stderr, e)
            exit(1)
        else
            rethrow()
        end
    end
else
    try
        Pkg.test(; kwargs...)
    catch e
        if e isa Pkg.Types.PkgError
            # don't show the stacktrace of the test harness because it's not useful
            showerror(stderr, e)
            exit(1)
        else
            rethrow()
        end
    end
end
