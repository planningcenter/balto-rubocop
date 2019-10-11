const exec = require("@actions/exec")

async function run() {
  await exec.exec('sh -l', [`${__dirname}/action/install-gems.sh`])
  await exec.exec('ruby', [`${__dirname}/action/action.rb`])
}


run()
