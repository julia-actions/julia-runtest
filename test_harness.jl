import Pkg
include("kwargs.jl")
kwargs = Kwargs.kwargs(; coverage=ENV["COVERAGE"],
                         force_latest_compatible_version=ENV["FORCE_LATEST_COMPATIBLE_VERSION"],
                         allow_reresolve=ENV["ALLOW_RERESOLVE"],
                         julia_args=[string("--check-bounds=", ENV["CHECK_BOUNDS"]),
                                     string("--compiled-modules=", ENV["COMPILED_MODULES"])])

if parse(Bool, ENV["ANNOTATE"]) && v"1.8pre" < VERSION < v"1.9.0-beta3"
    push!(LOAD_PATH, "@tests-logger-env") # access dependencies
    using GitHubActions, Logging
    global_logger(GitHubActionsLogger())
    include("test_logger.jl")
    pop!(LOAD_PATH)
    TestLogger.test(; kwargs...)
else
    Pkg.test(; kwargs...)
end
