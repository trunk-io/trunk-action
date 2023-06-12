const core = require("@actions/core");
const fs = require("fs");

function run() {
  try {
    core.info("running action");
    const filepath = process.env.GITHUB_EVENT_PATH;
    if (!filepath) {
      core.setFailed("No GITHUB_EVENT_PATH env var");
      return;
    }
    const event = JSON.parse(fs.readFileSync(filepath).toString());
    core.setSecret(event?.payload?.githubToken ?? core.getInput("githubToken") ?? "");
    core.setSecret(event?.payload?.trunkToken ?? core.getInput("trunkToken") ?? "");
  } catch (error) {
    if (error instanceof Error) core.setFailed(error.message);
  }
}

run();
