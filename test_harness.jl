import Pkg
include("kwargs.jl")
kwargs = Kwargs.kwargs(; coverage=ENV["COVERAGE"],
                         force_latest_compatible_version=ENV["FORCE_LATEST_COMPATIBLE_VERSION"],
                         allow_reresolve=ENV["ALLOW_RERESOLVE"],
                         julia_args=[string("--check-bounds=", ENV["CHECK_BOUNDS"]),
                                     string("--compiled-modules=", ENV["COMPILED_MODULES"]),
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
