const process = require('process')
const core = require('@actions/core')
const exec = require('@actions/exec')
const io = require('@actions/io')

async function run() {
  process.chdir(process.env['INPUT_ROOTDIRECTORY'])
  const baltoGemfile = 'balto-rubocop.gemfile'

  try {
    await exec.exec('ruby', [`${__dirname}/action/create_minimal_gemfile.rb`])

    const bundle = await io.which("bundle", true)
    const customEnv = process.env
    customEnv.BUNDLE_GEMFILE = baltoGemfile
    customEnv.BUNDLE_APP_CONFIG = '/dev/null'

    await exec.exec(bundle, ['install'], { env: customEnv })
    const { exitCode, stdout, stderr } = await exec.getExecOutput(
      bundle, 
      ['exec', `${__dirname}/action/action.rb`],
      { env: customEnv, ignoreReturnCode: true }
    )
    if (exitCode > 0) {
      core.debug(`exit code: ${exitCode}`)
      core.debug(`stdout: ${stdout}`)
      core.debug(`stderr: ${stderr}`)
      core.setFailed(stderr)
    }
  } catch (e) {
    core.setFailed(e.message)
  } finally {
    await exec.exec('git', ['clean', '-dfq', baltoGemfile, `${baltoGemfile}.lock`, 'Gemfile.lock'])
  }
}

run()
