module TestWrapper
using IOCapture, Pkg, GitHubActions, Logging

function collect_test_outputs(args...; kwargs...)
    return IOCapture.capture(; rethrow=InterruptException) do
        Pkg.test(args...; kwargs...)
    end
end

function parse_and_relog(output)
    r = r"(\e\[91m\e\[1m)?Test Failed(\e\[22m\e\[39m)? at (\e\[39m\e\[1m)?(?<path>[^\s\e]+)(\e\[22m)?\n\h*Expression:\h*(?<expression>[^\n]+)\h*\n\h*Evaluated:\h*(?<evaluated>[^\n]+)\h*\n"
    matches = eachmatch(r, output)
    for m in matches
        msg = "Test Failed"
        if !isnothing(m[:expression]) && !isnothing(m[:evaluated])
                msg = string(msg, "\nExpression: ", m[:expression], "\n", "Evaluated: ", m[:evaluated])
        end
        if m[:path] === nothing
            path = nothing
            line = nothing
        else
            path_split_results = rsplit(m[:path], ":", limit=2)
            if length(path_split_results) == 1
                path = m[:path]
            else
                path, line = path_split_results
            end
        end
        @error msg _file = path _line = line
    end
end

function test(args...; kwargs...)
    res = collect_test_outputs(args...; kwargs...)
    with_logger(GitHubActionsLogger()) do
        parse_and_relog(res.output)
    end
    print(res.output)
    if res.error
        throw(res.value)
    end
    return nothing
end

end # module
