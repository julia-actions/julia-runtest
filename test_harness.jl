import Pkg
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

# Warn if running on a merge commit (different from branch HEAD)
git_note = ""
if haskey(ENV, "GITHUB_SHA") && get(ENV, "GITHUB_EVENT_NAME", "") == "pull_request" && haskey(ENV, "GITHUB_HEAD_REF")
    # For pull_request events, GITHUB_SHA is the merge commit, not the PR head commit
    try
        merge_commit = ENV["GITHUB_SHA"]
        pr_branch = ENV["GITHUB_HEAD_REF"]
        base_branch_name = get(ENV, "GITHUB_BASE_REF", "")

        # Check if there's any difference between the merge commit and the PR head
        # In GitHub Actions, HEAD^2 is the PR head (second parent of merge commit)
        # success() returns true if the command exits with 0 (no differences)
        has_diff = !success(`git diff --quiet --exit-code HEAD^2 HEAD`)

        if has_diff
            base_branch = isempty(base_branch_name) ? "the base branch" : "'$base_branch_name'"
            global git_note = """
            │ Note: This is being run on merge commit $merge_commit (merge of PR branch '$pr_branch' into $base_branch).
            │ The content differs from the actual commit on your PR branch.
            │ To reproduce locally, update your branch with $base_branch first.
            │
            """
        end
    catch e
        @warn "Error while checking git diff" exception=(e, catch_backtrace())
    end
end

print("""
│
│ To reproduce this CI run locally run the following from the same repository state on julia version $VERSION:
│
│ `import Pkg; Pkg.test(;$kwargs_repr)`
│
""")
print(git_note)

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
