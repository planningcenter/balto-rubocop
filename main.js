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
    const envWithCustomGemfile = process.env
    envWithCustomGemfile.BUNDLE_GEMFILE = baltoGemfile

    await exec.exec(bundle, ['install'], { env: envWithCustomGemfile })
    await exec.exec(
      bundle, 
      ['exec', `${__dirname}/action/action.rb`],
      { env: envWithCustomGemfile }
    )
  } catch (e) {
    core.setFailed(e.message)
  } finally {
    await exec.exec('git', ['clean', '-dfq', baltoGemfile, `${baltoGemfile}.lock`, 'Gemfile.lock'])
  }
}

run()
