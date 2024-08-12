# julia-runtest Action

This action runs the tests in a Julia package.

## Usage

Julia needs to be installed before this action can run. This can easily be achieved with the [setup-julia](https://github.com/marketplace/actions/setup-julia-environment) action.

An example workflow that uses this action might look like this:

```yaml
name: Run tests

on:
  push:
    branches:
      - master
      - main
  pull_request:

# needed to allow julia-actions/cache to delete old caches that it has created
permissions:
  actions: write
  contents: read

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        julia-version: ['lts', '1', 'pre']
        julia-arch: [x64, x86]
        os: [ubuntu-latest, windows-latest, macOS-latest]
        exclude:
          - os: macOS-latest
            julia-arch: x86

    steps:
      - uses: actions/checkout@v4
      - uses: julia-actions/setup-julia@v2
        with:
          version: ${{ matrix.julia-version }}
          arch: ${{ matrix.julia-arch }}
      - uses: julia-actions/cache@v2
      - uses: julia-actions/julia-buildpkg@v1
      - uses: julia-actions/julia-runtest@v1
        # with:
        #   annotate: true
```

You can add this workflow to your repository by placing it in a file called `test.yml` in the folder `.github/workflows/`. [More info here](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions).

Here, setting `annotate: true` causes GitHub "annotations" to appear when reviewing the PR, pointing to failing tests, if any.
This functionality is only enabled on Julia 1.8 (even if `annotate` is set to `true`), since currently it does not work on other Julia versions (see [#76](https://github.com/julia-actions/julia-runtest/issues/76)).

By default, `annotate` is set to false, but that may change in future releases of this action.
### Prefixing the Julia command

In some packages, you may want to prefix the `julia` command with another command, e.g. for running tests of certain graphical libraries with `xvfb-run`.
In that case, you can add an input called `prefix` containing the command that will be inserted to your workflow:

```yaml
      - uses: julia-actions/julia-runtest@v1
        with:
          prefix: xvfb-run
```

If you only want to add this prefix on certain builds, you can [include additional values into a combination](https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-syntax-for-github-actions#example-including-additional-values-into-combinations) of your build matrix, e.g.:

```yaml
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macOS-latest]
        version: ['lts', '1', 'pre']
        arch: [x64]
        include:
          - os: ubuntu-latest
            prefix: xvfb-run
    steps:
    # ...
      - uses: julia-actions/julia-runtest@v1
        with:
          prefix: ${{ matrix.prefix }}
    # ...
```

This will add the prefix `xvfb-run` to all builds where the `os` is `ubuntu-latest`.

### Pass Arguments to Test Suite

You can pass arguments from the workflow specification to the test script via the `test_args` parameter.

This is useful, for example, to specify separate workflows for fast and slow tests, or conditionally enabling quality assurance tests.

The functionality can be incorporated as follows:

```yaml
    # ...
    steps:
    # ...
      - uses: julia-actions/julia-runtest@v1
        with:
          test_args: 'slow_tests "quality assurance"'
    # ...
```

The value of `test_args` can be accessed in `runtest.jl` via the `ARGS` variable. An example for `runtest.jl` is given below.

```julia
using Test
# ...

# run fast tests by default
include("fast_tests.jl")

if @isdefined(ARGS) && length(ARGS) > 0 && ARGS[1] == "slow_tests"
    # run slow tests
    include("slow_tests.jl")
end

if @isdefined(ARGS) && length(ARGS) > 0 && ARGS[1] == "quality assurance"
    # run quality assurance tests
    include("qa.jl")
end
```


### Registry flavor preference

This actions defines (and exports for subsequent steps of the workflow) the
environmental variable `JULIA_PKG_SERVER_REGISTRY_PREFERENCE=eager` unless it
is already set. If you want another registry flavor (i.e. `conservative`) this
should be defined in the `env:` section of the relevant workflow or step. See
[Registry flavors](https://pkgdocs.julialang.org/dev/registries/#Registry-flavors)
for more information.
