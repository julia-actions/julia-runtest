import * as core from '@actions/core'
import * as exec from '@actions/exec'

async function run() {
    try {
        const codecov = core.getInput('codecov')
        const coveralls = core.getInput('coveralls')

        // Run Pkg.build
        await exec.exec('julia', ['--color=yes', '--project', '-e', 'using Pkg; if VERSION >= v\"1.1.0-rc1\"; Pkg.build(verbose=true); else Pkg.build(); end'])

        // Run Pkg.test
        await exec.exec('julia', ['--color=yes', '--check-bounds=yes', '--project', '-e', 'using Pkg; Pkg.test(coverage=true)'])

        if(codecov=='true') {
            // await exec.exec('julia', ['--color=yes', '-e', 'using Pkg; Pkg.add("Coverage"); using Coverage; Codecov.submit(process_folder())'])
            await exec.exec('julia', ['--color=yes', '-e', 'using Pkg; Pkg.add(PackageSpec(url="https://github.com/davidanthoff/Coverage.jl.git", rev="githubactions")); using Coverage; Codecov.submit(process_folder())'])
        }

        // if(coveralls=='true') {
        //     await exec.exec('julia', ['--color=yes', '-e', 'using Pkg; Pkg.add("Coverage"); using Coverage; Coveralls.submit(process_folder())'])
        // }
    } catch (error) {
        core.setFailed(error.message)
    }
}

run()
