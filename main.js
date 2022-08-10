const process = require('process')
const core = require('@actions/core')
const exec = require('@actions/exec')
const io = require('@actions/io')

async function run() {
  process.chdir(process.env['INPUT_ROOTDIRECTORY'])
  const baltoDir = 'balto-rubocop-tmp'

  try {
    await io.mkdirP(baltoDir)

    await exec.exec('ruby', [`${__dirname}/action/create_minimal_gemfile.rb`])

    const bundle = await io.which("bundle", true)
    const envWithCustomGemfile = process.env
    envWithCustomGemfile.BUNDLE_GEMFILE = `${baltoDir}/Gemfile`

    await exec.exec(bundle, ['install'], { env: envWithCustomGemfile })
    await exec.exec(
      bundle, 
      ['exec', `${__dirname}/action/action.rb`],
      { env: envWithCustomGemfile }
    )
  } catch (e) {
    core.setFailed(e.message)
  } finally {
    await io.rmRF(baltoDir)
  }
}

run()
