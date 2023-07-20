#!/usr/bin/env node

const chai = require("chai");
const fs = require("fs");

const filePath = "./local-action/tmp/trunk-execution.log";
const logContent = fs.readFileSync(filePath, "utf-8").split("\n");
const { expect } = chai;
const upstream = "50039e906e0e53ce03b269e5e9e00879f4c6f05c";
const githubCommit = "69b531ac8f611e0ae73639ec606fbc23e8ead576";

if (process.env.TRUNK_CHECK_MODE === "trunk_merge") {
  expect(logContent.slice(-1)).to.deep.equal([""]);
  expect(logContent.slice(0, -1).map(JSON.parse)).to.deep.equal([
    [
      process.env.TRUNK_PATH,
      "check",
      "--ci",
      "--upstream",
      upstream,
      "--github-commit",
      githubCommit,
      "--github-label",
      "",
    ],
  ]);
}
if (process.env.TRUNK_CHECK_MODE === "pull_request") {
  expect(logContent.slice(-1)).to.deep.equal([""]);
  expect(logContent.slice(0, -1).map(JSON.parse)).to.deep.equal([
    [
      process.env.TRUNK_PATH,
      "check",
      "--ci",
      "--upstream",
      upstream,
      "--github-commit",
      githubCommit,
      "--github-label",
      "",
    ],
  ]);
}
if (process.env.TRUNK_CHECK_MODE === "all") {
  expect(logContent.slice(-1)).to.deep.equal([""]);
  expect(logContent.slice(0, -1).map(JSON.parse)).to.deep.equal([
    [
      process.env.TRUNK_PATH,
      "check",
      "--all",
      "--upload",
      "--series",
      "main",
      "--token",
      process.env.INPUT_TRUNK_TOKEN,
    ],
  ]);
}
