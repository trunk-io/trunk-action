const fs = require("fs");
const crypto = require("crypto");

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

function envWrite({ payload, fd, varname, path, backup = "" }) {
  let toWrite = payload;
  path.split(".").forEach((arg) => {
    toWrite = toWrite[arg] ?? {};
  });
  if (!["string", "boolean", "number"].some((type) => typeof toWrite === type)) {
    toWrite = backup;
  }
  fs.writeSync(fd, Buffer.from(`${varname}=${toWrite ?? ""}\n`));
}

function run() {
  try {
    const inputs = JSON.parse(process.env.MASK_INPUTS ?? "{}");
    const githubEventPR = JSON.parse(process.env.MASK_GITHUB_EVENT_PR ?? "{}");

    const filepath = process.env.GITHUB_EVENT_PATH;
    let payload = {};
    if (inputs["check-mode"] === "payload" && filepath) {
      const event = JSON.parse(fs.readFileSync(filepath).toString());
      payload = JSON.parse(event?.inputs?.payload) ?? {};
    }

    const githubEnv = fs.openSync(process.env.GITHUB_ENV, "a");
    const githubToken = payload?.githubToken ?? inputs["githubToken"] ?? "";
    const trunkToken = payload?.trunkToken ?? inputs["trunkToken"] ?? "";

    process.stdout.write(`::add-mask::${githubToken}\n`);
    process.stdout.write(`::add-mask::${trunkToken}\n`);
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
        backup: githubEventPR?.base?.sha ?? "",
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK",
        path: "pullRequest.head.repo.fork",
        backup: githubEventPR?.head?.repo?.fork ?? "",
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_HEAD_SHA",
        path: "pullRequest.head.sha",
        backup: githubEventPR?.head?.sha ?? "",
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_NUMBER",
        path: "pullRequest.number",
        backup: githubEventPR?.number ?? "",
      },
      { varname: "GITHUB_REF_NAME", path: "targetRefName", backup: process.env.GITHUB_REF_NAME },
      { varname: "INPUT_ARGUMENTS", path: "arguments", backup: inputs["arguments"] },
      { varname: "INPUT_CACHE", path: "cache", backup: inputs["cache"] },
      {
        varname: "INPUT_CACHE_KEY",
        path: "cacheKey",
        backup: `trunk-${inputs["cache-key"]}-${process.env.RUNNER_OS}-${hashFile(
          ".trunk/trunk.yaml"
        )}`,
      },
      { varname: "INPUT_CACHE_PATH", path: "cachePath", backup: "~/.cache/trunk" },
      { varname: "INPUT_CHECK_ALL_MODE", path: "checkAllMode", backup: inputs["check-all-mode"] },
      { varname: "INPUT_CHECK_MODE", path: "checkMode", backup: inputs["check-mode"] },
      { varname: "INPUT_CHECK_RUN_ID", path: "checkRunId", backup: inputs["check-run-id"] },
      { varname: "INPUT_DEBUG", path: "debug", backup: inputs["debug"] },
      {
        varname: "INPUT_GITHUB_REF_NAME",
        path: "targetRefName",
        backup: process.env.GITHUB_REF_NAME,
      },
      { varname: "INPUT_LABEL", path: "label", backup: inputs["label"] },
      { varname: "INPUT_SETUP_CACHE_KEY", path: "setupCacheKey", backup: inputs["cache-key"] },
      { varname: "INPUT_SETUP_DEPS", path: "setupDeps", backup: inputs["setup-deps"] },
      { varname: "INPUT_TARGET_CHECKOUT", path: "targetCheckout", backup: "" },
      { varname: "INPUT_TARGET_CHECKOUT_REF", path: "targetCheckoutRef", backup: "" },
      { varname: "INPUT_TRUNK_PATH", path: "trunkPath", backup: inputs["trunk-path"] },
      { varname: "INPUT_UPLOAD_LANDING_STATE", path: "uploadLandingState", backup: "false" },
      { varname: "INPUT_UPLOAD_SERIES", path: "uploadSeries", backup: inputs["upload-series"] },
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
