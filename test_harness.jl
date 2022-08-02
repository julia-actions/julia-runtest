import Pkg
include("kwargs.jl")
kwargs = Kwargs.kwargs(; coverage=ENV["COVERAGE"],
                         force_latest_compatible_version=ENV["FORCE_LATEST_COMPATIBLE_VERSION"],
                         julia_args=[string("--check-bounds=", ENV["CHECK_BOUNDS"])])

if parse(Bool, ENV["ANNOTATE"]) && VERSION > v"1.8pre"
    push!(LOAD_PATH, "@tests-logger-env") # access dependencies
    using GitHubActions, Logging
    global_logger(GitHubActionsLogger())
    include("test_logger.jl")
    pop!(LOAD_PATH)
    TestLogger.test(; kwargs...)        
else
    Pkg.test(; kwargs...)        
end
