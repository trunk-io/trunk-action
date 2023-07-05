const fs = require("fs");

const upstream = "50039e906e0e53ce03b269e5e9e00879f4c6f05c";
const githubCommit = "69b531ac8f611e0ae73639ec606fbc23e8ead576";

const pullRequestCommand = `${TRUNK_PATH} check \
    --ci \
    --upstream ${upstream} \
    --github-commit ${githubCommit} \
    --github-label "${process.env[INPUT_LABEL]}" \
    --token "${process.env[INPUT_TRUNK_TOKEN]}"`;

function checkFileContent(expectedCliInvocation) {
  try {
    const filePath = "/tmp/trunk-execution.log";
    const fileContent = fs.readFileSync(filePath, "utf-8");
    const matches = fileContent.includes(expectedCliInvocation);
    process.stdout.write(`${fileContent}`);
    process.stdout.write(`${matches ? "Success!" : "Does not match"}`);
    return matches;
  } catch (error) {
    process.stdout.write("Error reading the file:", error);
    return false;
  }
}

function run() {
  if (process.env.INPUT_CHECK_MODE === "pull_request") {
    return checkFileContent(pullRequestCommand);
  } else if (process.env.INPUT_CHECK_MODE === "all") {
  } else if (process.env.INPUT_CHECK_MODE === "trunk_merge") {
  }
}

run();
