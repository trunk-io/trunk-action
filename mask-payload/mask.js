const fs = require("fs");

function run() {
  try {
    process.stdout.write("running action\n");
    const filepath = process.env.GITHUB_EVENT_PATH;
    if (!filepath) {
      process.exitCode = ExitCode.Failure;
      process.stdout.write("::error::No GITHUB_EVENT_PATH env var");
      return;
    }
    const event = JSON.parse(fs.readFileSync(filepath).toString());
    process.stdout.write(
      `::add-mask::${event?.payload?.githubToken ?? core.getInput("githubToken") ?? ""}`
    );
    process.stdout.write(
      `::add-mask::${event?.payload?.trunkToken ?? core.getInput("trunkToken") ?? ""}`
    );
  } catch (error) {
    if (error instanceof Error) {
      process.exitCode = ExitCode.Failure;
      process.stdout.write(error.message);
    }
    return;
  }
}

run();
