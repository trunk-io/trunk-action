#!/usr/bin/env node

const fs = require("fs");
const path = require("node:path");

const getArgv = () => {
  if (path.basename(process.argv[1]) === "stub.js") {
    return ["trunk"].concat(process.argv.slice(2));
  }

  fs.appendFileSync(
    process.env.TRUNK_STUB_LOGS,
    JSON.stringify({
      error: "Failed to sanitize argv",
      argv: process.argv,
    }),
  );
  fs.appendFileSync(process.env.TRUNK_STUB_LOGS, "\n");
  return process.argv;
};

// process.argv will look like ['/abs/path/to/node', '/abs/path/to/stub.js', ...]
// We only want to assert that the calls look like ['trunk', 'check', '--ci', ...], hence the rewrite
const argv = getArgv();

fs.appendFileSync(process.env.TRUNK_STUB_LOGS, JSON.stringify(argv));
fs.appendFileSync(process.env.TRUNK_STUB_LOGS, "\n");

if (argv[1] === "check" && argv[2] === "get-latest-raw-output") {
  process.stdout.write(process.env.STUB_GET_LATEST_RAW_OUTPUT_STDOUT);
}

if (argv[1] === "version") {
  process.stdout.write(process.env.TRUNK_CLI_VERSION || "99.99.99");
}

// Optional delay so CI can exercise `timeout` wrapping `pull_request.sh` (see action_tests.yaml).
// Skip `trunk check get-latest-raw-output` / `trunk check list` etc. — only slow down `trunk check --flags...`.
if (argv[1] === "check") {
  const sub = argv[2];
  const sleepOk = !sub || sub.startsWith("-");
  const sec = Number(process.env.TRUNK_STUB_SLEEP_SECONDS || 0);
  if (sleepOk && Number.isFinite(sec) && sec > 0) {
    const { execSync } = require("node:child_process");
    execSync(`sleep ${Math.floor(sec)}`, { stdio: "inherit" });
  }
}
