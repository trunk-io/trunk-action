import * as core from "@actions/core";
import { readFileSync } from "fs";

async function run(): Promise<void> {
  try {
    core.info("running action");
    const filepath = process.env.GITHUB_EVENT_PATH;
    if (!filepath) {
      core.setFailed("No GITHUB_EVENT_PATH env var");
      return;
    }
    const event = JSON.parse(readFileSync(filepath).toString());
    core.setSecret(event?.payload?.githubToken ?? core.getInput("githubToken") ?? "");
    core.setSecret(event?.payload?.trunkToken ?? core.getInput("trunkToken") ?? "");
  } catch (error) {
    if (error instanceof Error) core.setFailed(error.message);
  }
}

run();
