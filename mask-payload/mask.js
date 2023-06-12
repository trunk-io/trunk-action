const fs = require("fs");
const crypto = require("crypto");

function getInput(input_name) {
  // copied from https://github.com/actions/toolkit/blob/master/packages/core/src/core.ts#L69
  return process.env[`INPUT_${input_name.replace(/ /g, "_").toUpperCase()}`] || "";
}

function hashFile(filename) {
  try {
    const data = fs.readFileSync(filename).toString();
    return crypto.createHash("sha256").update(data).digest("hex");
  } catch (err) {
    if (err.message.includes("ENOENT")) {
      return "";
    }
    throw err;
  }
}

function envWrite({ payload, fd, varname, path, backup }) {
  let toWrite = payload;
  path.split(".").forEach((arg) => {
    console.log(JSON.stringify(arg, null, 2));
    toWrite = toWrite[arg] ?? {};
  });
  console.log("final toWrite", toWrite);
  if (!["string", "boolean", "number"].some((type) => typeof toWrite === type)) {
    toWrite = backup;
  }
  console.log(`writing ${varname}=${toWrite ?? ""}`);
  fs.writeSync(fd, Buffer.from(`${varname}=${toWrite ?? ""}\n`));
}

function run() {
  try {
    const filepath = process.env.GITHUB_EVENT_PATH;
    let payload = {};
    if (getInput("check-mode") === "payload" && filepath) {
      payload = JSON.parse(fs.readFileSync(filepath).toString())?.payload ?? {};
    }

    console.log(JSON.stringify(payload, null, 2));

    const githubEnv = fs.openSync(process.env.GITHUB_ENV, "a");
    const githubToken = payload?.githubToken ?? getInput("githubToken");
    const trunkToken = payload?.trunkToken ?? getInput("trunkToken");

    process.stdout.write(`::add-mask::${githubToken}`);
    process.stdout.write(`::add-mask::${trunkToken}`);
    fs.writeSync(githubEnv, Buffer.from(`INPUT_GITHUB_TOKEN=${githubToken}\n`));
    fs.writeSync(githubEnv, Buffer.from(`INPUT_TRUNK_TOKEN=${trunkToken}\n`));
    fs.writeSync(githubEnv, Buffer.from(`TRUNK_TOKEN=${trunkToken}\n`));

    const envVarConfigs = [
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_BASE_REPO_OWNER",
        path: "pullRequest.base.repo.owner.login",
        backup: "",
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_BASE_REPO_NAME",
        path: "pullRequest.base.repo.name",
        backup: "",
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_BASE_SHA",
        path: "pullRequest.base.sha",
        backup: process.env.GITHUB_EVENT_PULL_REQUEST_BASE_SHA,
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK",
        path: "pullRequest.head.repo.fork",
        backup: process.env.GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK,
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_HEAD_SHA",
        path: "pullRequest.head.sha",
        backup: process.env.GITHUB_EVENT_PULL_REQUEST_HEAD_SHA,
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_NUMBER",
        path: "pullRequest.number",
        backup: process.env.GITHUB_EVENT_PULL_REQUEST_NUMBER,
      },
      { varname: "GITHUB_REF_NAME", path: "targetRefName", backup: process.env.GITHUB_REF_NAME },
      { varname: "INPUT_ARGUMENTS", path: "arguments", backup: getInput("arguments") },
      { varname: "INPUT_CACHE", path: "cache", backup: getInput("cache") },
      {
        varname: "INPUT_CACHE_KEY",
        path: "cacheKey",
        backup: `trunk-${getInput("cache-key")}-${process.env.RUNNER_OS}-${hashFile(
          ".trunk/trunk.yaml"
        )}`,
      },
      { varname: "INPUT_CACHE_PATH", path: "cachePath", backup: "~/.cache/trunk" },
      { varname: "INPUT_CHECK_ALL_MODE", path: "checkAllMode", backup: getInput("check-all-mode") },
      { varname: "INPUT_CHECK_MODE", path: "checkMode", backup: getInput("check-mode") },
      { varname: "INPUT_CHECK_RUN_ID", path: "checkRunId", backup: getInput("check-run-id") },
      { varname: "INPUT_DEBUG", path: "debug", backup: getInput("debug") },
      {
        varname: "INPUT_GITHUB_REF_NAME",
        path: "targetRefName",
        backup: process.env.GITHUB_REF_NAME,
      },
      { varname: "INPUT_LABEL", path: "label", backup: getInput("label") },
      { varname: "INPUT_SETUP_CACHE_KEY", path: "setupCacheKey", backup: getInput("cache-key") },
      { varname: "INPUT_SETUP_DEPS", path: "setupDeps", backup: getInput("setup-deps") },
      { varname: "INPUT_TARGET_CHECKOUT", path: "targetCheckout", backup: "" },
      { varname: "INPUT_TARGET_CHECKOUT_REF", path: "targetCheckoutRef", backup: "" },
      { varname: "INPUT_TRUNK_PATH", path: "trunkPath", backup: getInput("trunk-path") },
      { varname: "INPUT_UPLOAD_LANDING_STATE", path: "uploadLandingState", backup: "false" },
      { varname: "INPUT_UPLOAD_SERIES", path: "uploadSeries", backup: getInput("upload-series") },
    ];

    envVarConfigs.forEach(({ varname, path, backup }) =>
      envWrite({ payload, fd: githubEnv, varname, path, backup })
    );
    fs.closeSync(githubEnv);
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
