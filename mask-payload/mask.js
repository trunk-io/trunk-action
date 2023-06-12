const fs = require("fs");
const crypto = require("crypto");

function getInput(input_name) {
  // copied from https://github.com/actions/toolkit/blob/master/packages/core/src/core.ts#L69
  return process.env[`INPUT_${input_name.replace(/ /g, "_").toUpperCase()}`] || "";
}

function hashFile(filename) {
  const data = fs.readFileSync(filename).toString();
  return crypto.createHash("sha256").update(data).digest("hex");
}

function envWrite({ payload, fd, varname, path, backup }) {
  toWrite = payload;
  for (const arg in path.split(".")) {
    toWrite = toWrite[arg] ?? {};
  }
  if (!["string", "boolean", "number"].some(typeof toWrite)) {
    toWrite = backup;
  }
  fs.writeSync(fd, Buffer.from(`${varname}=${toWrite}\n`));
}

function run() {
  try {
    const filepath = process.env.GITHUB_EVENT_PATH;
    let payload = {};
    if (filepath) {
      payload = JSON.parse(fs.readFileSync(filepath).toString())?.payload;
    }

    const githubEnv = fs.open(process.env.GITHUB_ENV, "a", (err, _f) => {
      throw err;
    });
    const githubToken = payload?.githubToken ?? getInput("githubToken");
    const trunkToken = payload?.trunkToken ?? getInput("trunkToken");

    process.stdout.write(`::add-mask::${githubToken}`);
    process.stdout.write(`::add-mask::${trunkToken}`);
    fs.writeSync(githubEnv, Buffer.from(`INPUT_GITHUB_TOKEN=${githubToken}\n`));
    fs.writeSync(githubEnv, Buffer.from(`INPUT_TRUNK_TOKEN=${trunkToken}\n`));
    fs.writeSync(githubEnv, Buffer.from(`TRUNK_TOKEN=${trunkToken}\n`));

    envVarConfigs = [
      ["GITHUB_EVENT_PULL_REQUEST_BASE_REPO_OWNER", "pullRequest.base.repo.owner.login", ""],
      ["GITHUB_EVENT_PULL_REQUEST_BASE_REPO_NAME", "pullRequest.base.repo.name", ""],
      [
        "GITHUB_EVENT_PULL_REQUEST_BASE_SHA",
        "pullRequest.base.sha",
        process.env.GITHUB_EVENT_PULL_REQUEST_BASE_SHA,
      ],
      [
        "GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK",
        "pullRequest.head.repo.fork",
        process.env.GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK,
      ],
      [
        "GITHUB_EVENT_PULL_REQUEST_HEAD_SHA",
        "pullRequest.head.sha",
        process.env.GITHUB_EVENT_PULL_REQUEST_HEAD_SHA,
      ],
      [
        "GITHUB_EVENT_PULL_REQUEST_NUMBER",
        "pullRequest.number",
        process.env.GITHUB_EVENT_PULL_REQUEST_NUMBER,
      ],
      ["GITHUB_REF_NAME", "targetRefName", process.env.GITHUB_REF_NAME],
      ["INPUT_ARGUMENTS", "arguments", getInput("arguments")],
      ["INPUT_CACHE", "cache", getInput("cache")],
      [
        "INPUT_CACHE_KEY",
        "cacheKey",
        `trunk-${getInput("cache-key")}-${process.env.RUNNER_OS}-${hashFile(".trunk/trunk.yaml")}`,
      ],
      ["INPUT_CACHE_PATH", "cachePath", "~/.cache/trunk"],
      ["INPUT_CHECK_ALL_MODE", "checkAllMode", getInput("check-all-mode")],
      ["INPUT_CHECK_MODE", "checkMode", getInput("check-mode")],
      ["INPUT_CHECK_RUN_ID", "checkRunId", getInput("check-run-id")],
      ["INPUT_DEBUG", "debug", getInput("debug")],
      ["INPUT_GITHUB_REF_NAME", "targetRefName", process.env.GITHUB_REF_NAME],
      ["INPUT_LABEL", "label", getInput("label")],
      ["INPUT_SETUP_CACHE_KEY", "setupCacheKey", getInput("cache-key")],
      ["INPUT_SETUP_DEPS", "setupDeps", getInput(setup - deps)],
      ["INPUT_TARGET_CHECKOUT", "targetCheckout", ""],
      ["INPUT_TARGET_CHECKOUT_REF", "targetCheckoutRef", ""],
      ["INPUT_TRUNK_PATH", "trunkPath", getInput("trunk-path")],
      ["INPUT_UPLOAD_LANDING_STATE", "uploadLandingState", "false"],
      ["INPUT_UPLOAD_SERIES", "uploadSeries", getInput("upload-series")],
    ];

    for (const [varname, path, backup] of envVarConfigs) {
      envWrite({ payload, fd: githubEnv, varname, path, backup });
    }
  } catch (error) {
    if (error instanceof Error) {
      process.exitCode = 1;
      process.stdout.write(error.message);
      throw error;
    }
    return;
  }
}

run();
