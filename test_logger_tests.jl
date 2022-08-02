include("test_logger.jl")
using Logging, Test

function simulate(text)
    logger = Test.TestLogger()
    output = IOBuffer()
    with_logger(logger) do
        stream, t = TestLogger.build_stream(output)
        for line in eachline(IOBuffer(text); keep=true)
            write(stream, line)
        end
        close(stream)
        wait(t)
    end
    return String(take!(output)), logger.logs
end

@testset "TestLogger" begin

    for input in (
            """
            Test Failed at file.txt:1
            1
            2
            3
            4
            5
            6
            Stacktrace:
            Hi
            """,
            # Let us mess with the stacktrace line
            """
            Test Failed at file.txt:1
            1
            2
            3
            4
            5
            6
               Stacktrace:   extra stuff
            Hi
            """)

        output, logs = simulate(input)
        @test output == input
        log = only(logs)
        @test log.message == "Test Failed\n1\n2\n3\n4\n5\n6"
        @test log.file == "file.txt"
        @test log.line == "1"
    end

    # Next, check that if we hit a Test Failed, and then hit another one before we get a stacktrace,
    # we just move on to handling the new one.
    input = """
    Test Failed at file.txt:1
    Nah
    Test Failed at file.txt:1
    Correct
    Stacktrace:
    Hi
    """

    output, logs = simulate(input)
    @test output == input

    log = only(logs)
    @test log.message == "Test Failed\nCorrect"
    @test log.file == "file.txt"
    @test log.line == "1"
end
