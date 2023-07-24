#!/usr/bin/env node

const chai = require("chai");
const fs = require("fs");
const path = require("path");

const { expect } = chai;

const stubLog = fs.readFileSync(process.env.TRUNK_STUB_LOGS, "utf8").split("\n");

// The last element of the split() should be an empty string
expect(stubLog.slice(-1)).to.deep.equal([""]);

const getHtlFactoriesPath = () => {
  const tmpdirContents = fs.readdirSync(process.env.TMPDIR);

  if (tmpdirContents.length === 0) {
    throw new Error(
      `TMPDIR=${process.env.TMPDIR} was empty; could not infer what --htl-factories-path should have been`,
    );
  }

  if (tmpdirContents.length > 1) {
    throw new Error(
      `TMPDIR=${process.env.TMPDIR} had multiple entries (${JSON.stringify(
        tmpdirContents,
      )}); could not infer what --htl-factories-path should have been`,
    );
  }

  return path.join(process.env.TMPDIR, tmpdirContents[0]);
};
const upstream = "50039e906e0e53ce03b269e5e9e00879f4c6f05c";
const githubCommit = "69b531ac8f611e0ae73639ec606fbc23e8ead576";

const EXPECTED_CLI_CALL_FACTORIES = {
  "trunk-merge": () => [
    [
      "trunk",
      "check",
      "--ci",
      "--upstream",
      process.env.EXPECTED_UPSTREAM,
      "--github-commit",
      process.env.EXPECTED_GITHUB_COMMIT,
      "--github-label",
      "",
    ],
  ],
  "all-hold-the-line-new-series": () => [
    ["trunk", "check", "get-latest-raw-output", "--series", "series-name", getHtlFactoriesPath()],
    [
      "trunk",
      "check",
      "--all",
      "--upload",
      "--upload-id",
      "test-upload-id",
      "--series",
      "series-name",
    ],
  ],
  "all-hold-the-line-existing-series": () => [
    ["trunk", "check", "get-latest-raw-output", "--series", "series-name", getHtlFactoriesPath()],
    [
      "trunk",
      "check",
      "--all",
      "--upload",
      `--htl-factories-path=${getHtlFactoriesPath()}`,
      "--upload-id",
      "test-upload-id",
      "--series",
      "series-name",
    ],
  ],
  "all-hold-the-line-no-upload-id": () => [
    ["trunk", "check", "get-latest-raw-output", "--series", "series-name", getHtlFactoriesPath()],
    ["trunk", "check", "--all", "--upload", "--series", "series-name"],
  ],
  "pull-request-payload": () => [
    ["trunk", "version"],
    ["trunk", "init"],
    [
      "trunk",
      "check",
      "--ci",
      "--upstream",
      upstream,
      "--github-commit",
      githubCommit,
      "--github-label",
      "",
    ],
  ],
};

const testCase = process.argv[2];
const expectedCliCalls = EXPECTED_CLI_CALL_FACTORIES[testCase]();

// Strip the last element before JSON.parse, because '' is not valid JSON.
const actualCliCalls = stubLog.slice(0, -1).map(JSON.parse);

expect(actualCliCalls).to.deep.equal(expectedCliCalls);

console.log(`Test passed: ${testCase}\n\nCLI calls were:\n${JSON.stringify(actualCliCalls)}`);
