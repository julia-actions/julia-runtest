module TestWrapper
using Pkg, GitHubActions, Logging

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
        with_logger(GitHubActionsLogger()) do
            @error msg _file = path _line = line
        end
    end
end

function test(args...; kwargs...)
    stream = Base.BufferStream()
    t = @async begin
        while !eof(stream)
            line = readline(stream)
            println(line)
            if contains(line, "Test Failed")
                failure_lines = [line]
                while !contains(line, "Stacktrace:")
                    line = readline(stream)
                    println(line)
                    push!(failure_lines, line)
                end
                parse_and_relog(join(failure_lines, "\n"))
            end
        end
    end
    Base.errormonitor(t)
    return Pkg.test(args...; kwargs..., io=stream)
end

end # module
