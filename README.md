# julia-runtest Action

This action runs the tests in a Julia package and uploads coverage results to [Coveralls](https://coveralls.io/) and [Codecov](https://codecov.io/).

## Usage

Julia needs to be installed before this action can run. This can easily be achieved with the [setup-julia](https://github.com/marketplace/actions/setup-julia-environment) action.

This action accepts two inpus: `codecov` (with values `true` or `false`) and `coveralls` (with values `true` or `false`). These inputs control whether coverage results are automatically uploaded to the respective service. Both inputs have a default value of `true`.

Uploads to [Coveralls](https://coveralls.io/) or [Codecov](https://codecov.io/) only work if an upload token for the respective service is stored as a Github Actions secret and made available to the action. These tokens need to be stored in the environment variables `CODECOV_TOKEN` and `COVERALLS_TOKEN`.

And example workflow that uses this action might look like this:

```
name: Run tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        julia-version: [stable, lts]
        julia-arch: [x64, x86]
        os: [ubuntu-latest, windows-latest, macOS-latest]
        exclude:
          - os: macOS-latest
            julia-arch: x86

    steps:
      - uses: actions/checkout@v1.0.0
      - uses: julia-actions/setup-julia@v0.2
        with:
          version: ${{ matrix.julia-version }}
      - uses: julia-actions/julia-runtest@master
        env:
          CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
          COVERALLS_TOKEN: ${{ secrets.COVERALLS_TOKEN }}
```
