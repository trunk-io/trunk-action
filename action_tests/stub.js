#!/usr/bin/env node

const fs = require("fs");
const path = require("node:path");

// process.argv will look like ['/abs/path/to/node', '/abs/path/to/stub.js', ...]
// We only want to assert that the calls look like ['trunk', 'check', '--ci', ...], hence the rewrite
const argv =
  path.basename(process.argv[1]) === "stub.js"
    ? ["trunk"].concat(process.argv.slice(2))
    : process.argv;

fs.appendFileSync(process.env.TRUNK_STUB_LOGS, JSON.stringify(process.argv));
fs.appendFileSync(process.env.TRUNK_STUB_LOGS, "\n");
