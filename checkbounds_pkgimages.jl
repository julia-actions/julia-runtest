# Since Julia 1.14, the stdlib pkgimages for `--check-bounds=yes` are not bundled
# with Julia but published as a separate `.checkbounds.tar.gz` companion archive
# next to each nightly and release tarball. Install the companion matching the
# running Julia into its own depot, so that the tests do not have to precompile
# the stdlibs first. Julia ignores caches that do not match, so on any failure the
# stdlibs are simply precompiled as before.

# Older versions bundle the images, and may predate `Downloads`
VERSION >= v"1.14.0-" || exit()

import Downloads, SHA

const NIGHTLIES = "https://julialangnightlies-s3.julialang.org/bin"
const RELEASES = "https://julialang-s3.julialang.org/bin"

# Builds from before the split, and custom builds, have no companion
struct NoCompanion <: Exception
    msg::String
end

function download(url, dest)
    try
        Downloads.download(url, dest)
    catch err
        if err isa Downloads.RequestError && err.response.status == 404
            throw(NoCompanion("$url does not exist"))
        end
        rethrow()
    end
end

# The (URL, sha256) of the companion for the running Julia, following the names used by
# JuliaCI/julia-buildkite. Nightlies are looked up by commit rather than `julia-latest`,
# which may already point to a newer build than the one that is installed.
function companion_url()
    os = Sys.islinux() ? "linux" : Sys.isapple() ? "macos" : Sys.iswindows() ? "windows" :
         Sys.isfreebsd() ? "freebsd" : throw(NoCompanion("unsupported platform $(Sys.KERNEL)"))
    arch = string(Sys.ARCH)
    majmin = "$(VERSION.major).$(VERSION.minor)"
    if !Base.GIT_VERSION_INFO.tagged_commit
        name = "julia-$(first(Base.GIT_VERSION_INFO.commit, 10))-$os-$arch.checkbounds.tar.gz"
        return "$NIGHTLIES/$os/$arch/$majmin/$name", nothing
    end
    folder_arch = arch == "x86_64" ? "x64" : arch == "i686" ? "x86" : arch
    platform = os == "macos" ? (arch == "x86_64" ? "mac64" : "mac$arch") :
               os == "windows" ? (arch == "x86_64" ? "win64" : "win32") : "$os-$arch"
    folder_os = os == "macos" ? "mac" : os == "windows" ? "winnt" : os
    name = "julia-$VERSION-$platform.checkbounds.tar.gz"
    checksums = String(take!(download("$RELEASES/checksums/julia-$VERSION.sha256", IOBuffer())))
    for line in eachline(IOBuffer(checksums))
        sha, file = split(line; limit=2)
        strip(file) == name && return "$RELEASES/$folder_os/$folder_arch/$majmin/$name", sha
    end
    throw(NoCompanion("$name is not listed in the release checksums"))
end

function install_companion(dir)
    url, sha = companion_url()
    tarball = joinpath(dir, "checkbounds.tar.gz")
    @info "Downloading bounds-checked stdlib pkgimages" url
    download(url, tarball)
    if sha !== nothing
        actual = bytes2hex(open(SHA.sha256, tarball))
        actual == sha || error("checksum mismatch for $url: expected $sha, got $actual")
    end
    # Use the system bsdtar on Windows, see julia-actions/setup-julia#205
    tar = Sys.iswindows() ? joinpath(ENV["WINDIR"], "System32", "tar.exe") : "tar"
    run(`$tar -xzf $tarball -C $dir`)
    rm(tarball)
    return joinpath(dir, "share", "julia")
end

function main()
    dir = mktempdir(get(ENV, "RUNNER_TEMP", tempdir()); prefix="julia-checkbounds-", cleanup=false)
    depot = try
        install_companion(dir)
    catch err
        if err isa NoCompanion
            @info "No separate bounds-checked stdlib pkgimages for this Julia: $(err.msg)"
        else
            println("::warning::Could not install the bounds-checked stdlib pkgimages, ",
                    "the stdlibs will be precompiled for `--check-bounds=yes` instead: ",
                    sprint(showerror, err))
        end
        return
    end
    open(ENV["GITHUB_OUTPUT"], "a") do io
        println(io, "depot_path=", join([DEPOT_PATH; depot], Sys.iswindows() ? ';' : ':'))
    end
end

main()
