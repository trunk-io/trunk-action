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

function run() {
  try {
    const inputs = JSON.parse(process.env.MASK_INPUTS ?? "{}");
    const githubEventPR = JSON.parse(process.env.MASK_GITHUB_EVENT_PR ?? "{}");

    let payload = {};

    const filepath = process.env.GITHUB_EVENT_PATH;
    const usePayload = process.env["INPUT_USE-PAYLOAD"] === "true";
    if (filepath && usePayload) {
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
        payloadValue: payload?.pullRequest?.base?.repo?.owner?.login,
        backup: "",
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_BASE_REPO_NAME",
        payloadValue: payload?.pullRequest?.base?.repo?.name,
        backup: "",
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_BASE_SHA",
        payloadValue: payload?.pullRequest?.base?.sha,
        backup: githubEventPR?.base?.sha ?? "",
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK",
        payloadValue: payload?.pullRequest?.head?.repo?.fork,
        backup: githubEventPR?.head?.repo?.fork ?? "",
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_HEAD_SHA",
        payloadValue: payload?.pullRequest?.head?.sha,
        backup: githubEventPR?.head?.sha ?? "",
      },
      {
        varname: "GITHUB_EVENT_PULL_REQUEST_NUMBER",
        payloadValue: payload?.pullRequest?.number,
        backup: githubEventPR?.number ?? "",
      },
      {
        varname: "GITHUB_REF_NAME",
        payloadValue: payload?.targetRefName,
        backup: process.env.GITHUB_REF_NAME,
      },
      { varname: "INPUT_ARGUMENTS", payloadValue: payload?.arguments, backup: inputs.arguments },
      { varname: "INPUT_CACHE", payloadValue: payload?.cache, backup: inputs.cache },
      {
        varname: "INPUT_CACHE_KEY",
        payloadValue: payload?.cacheKey,
        backup: `trunk-${inputs["cache-key"]}-${process.env.RUNNER_OS}-${hashFile(
          ".trunk/trunk.yaml"
        )}`,
      },
      { varname: "INPUT_CACHE_PATH", payloadValue: payload?.cachePath, backup: "~/.cache/trunk" },
      {
        varname: "INPUT_CHECK_ALL_MODE",
        payloadValue: payload?.checkAllMode,
        backup: inputs["check-all-mode"],
      },
      {
        varname: "INPUT_CHECK_MODE",
        payloadValue: payload?.checkMode,
        backup: inputs["check-mode"],
      },
      {
        varname: "INPUT_CHECK_RUN_ID",
        payloadValue: payload?.checkRunId,
        backup: inputs["check-run-id"],
      },
      { varname: "INPUT_DEBUG", payloadValue: payload?.debug, backup: inputs.debug },
      {
        varname: "INPUT_GITHUB_REF_NAME",
        payloadValue: payload?.targetRefName,
        backup: process.env.GITHUB_REF_NAME,
      },
      { varname: "INPUT_LABEL", payloadValue: payload?.label, backup: inputs.label },
      {
        varname: "INPUT_SETUP_CACHE_KEY",
        payloadValue: payload?.setupCacheKey,
        backup: inputs["cache-key"],
      },
      {
        varname: "INPUT_SETUP_DEPS",
        payloadValue: payload?.setupDeps,
        backup: inputs["setup-deps"],
      },
      { varname: "INPUT_TARGET_CHECKOUT", payloadValue: payload?.targetCheckout, backup: "" },
      {
        varname: "INPUT_TARGET_CHECKOUT_REF",
        payloadValue: payload?.targetCheckoutRef,
        backup: "",
      },
      {
        varname: "INPUT_TRUNK_PATH",
        payloadValue: payload?.trunkPath,
        backup: inputs["trunk-path"],
      },
      {
        varname: "INPUT_UPLOAD_LANDING_STATE",
        payloadValue: payload?.uploadLandingState,
        backup: "false",
      },
      {
        varname: "INPUT_UPLOAD_SERIES",
        payloadValue: payload?.uploadSeries,
        backup: inputs["upload-series"],
      },
    ];

    envVarConfigs.forEach(({ varname, payloadValue, backup }) =>
      fs.writeSync(
        githubEnv,
        Buffer.from(`${varname}=${(usePayload ? payloadValue : backup) ?? ""}\n`)
      )
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
