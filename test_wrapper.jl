module TestWrapper
using Pkg

function parse_file_line(failed_line)
    # The bits like `\e[91m\e[1m` are color codes that get printed by `Pkg.test`. We
    # match with or without them.
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
            path, line_no = path_split_results

            # Try to make sure line number is parseable to avoid false positives
            line_no = tryparse(Int, line_no) === nothing ? nothing : line_no
            return (path, line_no)
        end
    end
    return (nothing, nothing)
end

function readlines_until(f, stream; keep_lines=true, io)
    lines = String[]
    while true
        line = readline(stream; keep=true)
        print(io, line)

        # with `keep=true`, this should only happen when we're done?
        # I think so...
        if line == ""
            return line, lines
        end
        if f(line)
            return line, lines
        else
            keep_lines && push!(lines, line)
        end
    end
end

function has_test_failure(line)
    contains(line, "Test Failed") || return false
    file, line_no = parse_file_line(line)
    return !isnothing(file) && !isnothing(line_no)
end

function build_stream(io)
    stream = Base.BufferStream()
    t = @async begin
        while !eof(stream)
            # Iterate through and print until we get to "Test Failed" and can parse it
            failed_line, _ = readlines_until(has_test_failure, stream; keep_lines=false, io)
            @label found_failed_line
            # Parse file and line out
            file, line_no = parse_file_line(failed_line)

            # Grab everything until the stacktrace, OR we hit another `Test Failed`
            stopped_line, msg_lines = readlines_until(stream; io) do line
                contains(line, "Stacktrace:") || has_test_failure(line)
            end

            # If we stopped because we hit a 2nd test failure,
            # let's assume somehow the stacktrace didn't show up for the first one.
            # Let's continue by trying to find the info for this one, by jumping back.
            if has_test_failure(stopped_line)
                failed_line = stopped_line
                @goto found_failed_line
            end

            if !isempty(msg_lines)
                msg = string("Test Failed\n", chomp(join(msg_lines)))
                # Now log it out
                @error msg _file=file _line=line_no
            end
        end
    end
    return stream, t
end


function test(args...; kwargs...)
    stream, t = build_stream(stdout)
    Base.errormonitor(t)
    return try
        Pkg.test(args...; kwargs..., io=stream)
    finally
        close(stream)
    end
end

end # module
