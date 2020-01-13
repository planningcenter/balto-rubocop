const exec = require("@actions/exec")

async function run() {
  await exec.exec('ruby', [`${__dirname}/action/install_gems.rb`])
  await exec.exec('ruby', [`${__dirname}/action/action.rb`])
}

run()
