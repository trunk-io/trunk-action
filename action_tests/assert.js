#!/usr/bin/env node

const chai = require("chai");
const fs = require("fs");

const { expect } = chai;

const stubLog = fs.readFileSync(process.env.TRUNK_STUB_LOGS, "utf8").split("\n");

// The last element of the split() should be an empty string
expect(stubLog.slice(-1)).to.deep.equal([""]);

// Strip the last element before JSON.parse, because '' is not valid JSON.
expect(stubLog.slice(0, -1).map(JSON.parse)).to.deep.equal([
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
]);
