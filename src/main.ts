import * as core from '@actions/core'
import * as exec from '@actions/exec'

async function run() {
    try {
        const inline: string = core.getInput('inline')
        // Run Pkg.test
        await exec.exec('julia', ['--color=yes', '--check-bounds=yes', '--inline=${inline}', '--project', '-e', 'using Pkg; Pkg.test(coverage=true)'])
    } catch (error) {
        core.setFailed(error.message)
    }
}

run()
