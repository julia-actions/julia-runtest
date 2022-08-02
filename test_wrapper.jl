module TestWrapper
using Pkg, Logging

function parse_file_line(failed_line)
    r = r"(\e\[91m\e\[1m)?Test Failed(\e\[22m\e\[39m)? at (\e\[39m\e\[1m)?(?<path>[^\s\e]+)(\e\[22m)?"
    m = match(r, failed_line)
    m === nothing && return (nothing, nothing)

    if m[:path] === nothing
        return (nothing, nothing)
    else
        path_split_results = rsplit(m[:path], ":", limit=2)
        if length(path_split_results) == 1
            return (m[:path], nothing)
        else
            path, line = path_split_results

            # Try to make sure line number is parseable to avoid false positives
            line = tryparse(Int, line) === nothing ? nothing : line
            return (path, line)
        end
    end
    return (nothing, nothing)
end

function readlines_until_print(stream, delim; keep_lines=true)
    lines = String[]
    while true
        line = readline(stream; keep=true)
        print(line)

        # with `keep=true`, this should only happen when we're done?
        # I think so...
        if line == ""
            return line, lines
        end
        if contains(line, delim)
            return line, lines
        else
            keep_lines && push!(lines, line)
        end
    end

end

function test(args...; kwargs...)
    stream = Base.BufferStream()
    t = @async begin
        while !eof(stream)
            # Iterate through and print until we get to "Test Failed"
            failed_line, _ = readlines_until_print(stream, "Test Failed"; keep_lines=false)

            # Try to parse file and line out
            file, line = parse_file_line(failed_line)

            # Couldn't parse? Probably a false positive, keep going
            (isnothing(file) || isnothing(line)) && continue

            # Could parse? Ok, grab everything until the stacktrace
            _, msg_lines = readlines_until_print(stream, "Stacktrace:")

            msg = string("Test Failed\n", chomp(join(msg_lines)))

            # Now log it out
            @error msg _file = file _line = line
        end
    end
    Base.errormonitor(t)
    return try
        Pkg.test(args...; kwargs..., io=stream)
    finally
        close(stream)
    end
end

end # module
