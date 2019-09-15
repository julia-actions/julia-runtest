import * as core from '@actions/core'
import * as exec from '@actions/exec'

import * as os from 'os'
import * as path from 'path'

// Store information about the environment
const osPlat = os.platform() // possible values: win32 (Windows), linux (Linux), darwin (macOS)
core.debug(`platform: ${osPlat}`)

async function run() {
    try {
        const codecov = core.getInput('codecov')
        const coveralls = core.getInput('coveralls')

        // Test if Julia has been installed by showing versioninfo()
        await exec.exec('julia', ['--color=yes', '--project', '-e', 'using Pkg; if VERSION >= v\"1.1.0-rc1\"; Pkg.build(verbose=true); else Pkg.build(); end'])
        await exec.exec('julia', ['--color=yes', '--check-bounds=yes', '--project', '-e', 'using Pkg; Pkg.test(coverage=true)'])

        // if(codecov=='true') {
        //     await exec.exec('julia', ['--color=yes', '-e', 'using Pkg; Pkg.add("Coverage"); using Coverage; Codecov.submit(process_folder())'])
        // }

        // if(coveralls=='true') {
        //     await exec.exec('julia', ['--color=yes', '-e', 'using Pkg; Pkg.add("Coverage"); using Coverage; Coveralls.submit(process_folder())'])
        // }
    } catch (error) {
        core.setFailed(error.message)
    }
}

run()
