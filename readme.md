<!-- markdownlint-disable first-line-heading -->

[![Trunk.io](https://user-images.githubusercontent.com/3904462/199616921-7861e331-c774-43bf-8c17-1ecd27d0a750.png)](https://trunk.io)

[![docs](https://img.shields.io/badge/-docs-darkgreen?logo=readthedocs&logoColor=ffffff)][docs]
[![vscode](https://img.shields.io/visual-studio-marketplace/i/trunk.io?color=0078d7&label=vscode&logo=visualstudiocode)][vscode]
[![slack](https://img.shields.io/badge/-slack-611f69?logo=slack)][slack]
[![openssf](https://api.securityscorecards.dev/projects/github.com/trunk-io/trunk-action/badge)](https://api.securityscorecards.dev/projects/github.com/trunk-io/trunk-action)

> **💡Tip**
>
> 🎉 New: [Trunk Flaky Tests](https://trunk.io/flaky-tests) detects, quarantines, and eliminates
> flaky tests.

# Trunk.io GitHub Action

> **Note**
>
> We strongly encourage using Trunk Code Quality's integration with GitHub to run Trunk Code Quality
> on CI. [Get started here!](https://docs.trunk.io/code-quality/ci-setup)

This action runs and shows inline annotations of issues found by
[Trunk Code Quality](https://docs.trunk.io/code-quality), a powerful meta linter and formatter.
Trunk runs hermetically, _locally_ or on CI, so you can always quickly see lint, formatting, and
security issues _before_ pushing your changes. See all supported linters
[here](https://docs.trunk.io/code-quality/linters/supported).

Trunk Code Quality is free for individual use, **free for open source projects**, and has a free
tier for team use in private repos. (See [pricing](https://trunk.io/pricing))

<p align="center">
  <img src="https://user-images.githubusercontent.com/46629651/232631742-645be266-5ea1-4a97-aa6d-6da868c056a8.png" height="300"/>
  <br>
  <em>Example annotations</em>
</p>

## Get Started

[Follow these instructions to set up Trunk Code Quality CI for your GitHub repository](https://docs.trunk.io/code-quality/ci-setup)

## Run it Yourself

To run Trunk Code Quality on your pull requests, add this file to your repo as
`.github/workflows/trunk-check.yaml`:

```yaml
name: Pull Request
on: [pull_request]
concurrency:
  group: ${{ github.head_ref || github.run_id }}
  cancel-in-progress: true

permissions: read-all

jobs:
  trunk_check:
    name: Trunk Code Quality Runner
    runs-on: ubuntu-latest
    permissions:
      checks: write # For trunk to post annotations
      contents: read # For repo checkout

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Trunk Code Quality
        uses: trunk-io/trunk-action@v1
```

See this repo's
[`pr.yaml`](https://github.com/trunk-io/trunk-action/blob/main/.github/workflows/pr.yaml) workflow
for further reference.

### Advanced

You can get a lot more out of Trunk Code Quality if you install it locally and commit a Trunk
configuration in your repository:

1. Install Trunk → `curl https://get.trunk.io -fsSL | bash`
2. Setup Trunk in your repo → `trunk init`
3. Locally check your changes for issues → `git commit -m "Create initial Trunk config" .trunk/`

You'll see that in `.trunk/trunk.yaml`, we implement strict versioning of the Trunk CLI and every
linter you're running. This allows you to control all linter versioning using `.trunk/trunk.yaml`,
as well as enable linters which require manual configuration.

By default, `trunk-io/trunk-action` will run all linters which we can automatically initialize and
set up for you. This works well in many cases, but there are some cases where it is insufficient.

For example, if you already have ESLint set up and depend on ESLint plugins such as
`@typescript-eslint/eslint-plugin`, you'll need to `trunk check enable eslint` and also
[add a custom setup action](#custom-setup) to install your `eslint` dependencies.

### Custom Setup

If you define a composite action in your repository at `.trunk/setup-ci/action.yaml`, we will
automatically run it before we run any linters. This can be important if, for example, a linter
needs some generated code to be present before it can run:

```yaml
name: Trunk Code Quality setup
description: Set up dependencies for Trunk Code Quality
runs:
  using: composite
  steps:
    - name: Build required trunk check inputs
      shell: bash
      run: bazel build ... --build_tag_filters=pre-lint

    - name: Install eslint dependencies
      shell: bash
      run: npm install
```

Alternatively, you can handle setup as a separate step in your workflow before running
`trunk-io/trunk-action`; note however that this approach is not compatible with Trunk's
GitHub-native integrations.

If you've setup basic testing on CI, you're already doing this for other CI jobs; do it here too 😉.

### Caching

To use GitHub Actions caching for Trunk, create a new workflow (for example,
`.github/worksflows/cache_trunk.yaml`) to run on any change to your Trunk configuration:

```yaml
on:
  push:
    branches: [main]
    paths: [.trunk/trunk.yaml]

permissions: read-all

jobs:
  cache_trunk:
    name: Cache Trunk
    runs-on: ubuntu-latest
    permissions:
      actions: write

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Trunk Check
        uses: trunk-io/trunk-action@v1
        with:
          check-mode: populate_cache_only
```

If you are using long-lived self-hosted runners you should _not_ create the above workflow, and you
should also disable caching by passing `cache: false` when running Trunk on your PRs:

```yaml
- name: Trunk Code Quality
  uses: trunk-io/trunk-action@v3
  with:
    cache: false
```

### Getting Inline Annotations for Fork PRs

Create an additional _new GitHub workflow_ to post annotations from fork PRs. This workflow needs to
be merged into your main branch before fork PRs will see annotations. It's important that the name
of the workflow in the workflow_runs section (here "Pull Request") matches the workflow which runs
`trunk check`:

```yaml
name: Annotate PR with trunk issues

on:
  workflow_run:
    workflows: ["Pull Request"]
    types: [completed]

jobs:
  trunk_check:
    name: Trunk Code Quality Annotate
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Trunk Check
        uses: trunk-io/trunk-action@v1
        with:
          post-annotations: true # only for fork PRs
```

This setup is necessitated by GitHub for
[security reasons](https://securitylab.github.com/research/github-actions-preventing-pwn-requests/).
The Trunk Action auto-detects this situation and uploads its results as an artifact instead of
trying to post them. Creating the new GitHub workflow above downloads this artifact and posts the
annotations.

This also works if you use both fork and non-fork PRs in your repo. In that case, non-fork PRs post
annotations in the regular manner, and fork PRs post annotations via the above workflow.

## Trunk Versioning

After you run `trunk init`, the `.trunk/trunk.yaml` file will contain a pinned version of Trunk to
use for your repo. When you run `trunk`, it will automatically detect which version you should be
running for a particular repo and download+run it. This means that everyone working in a repo, and
CI, all get the same results and the same experience - no more _"doesn't happen on my machine"_.
When you want to upgrade to a newer version, just run `trunk upgrade` and commit the updated
`trunk.yaml`.

## Run Trunk Outside of GitHub Actions

Trunk has a dead simple install, is totally self-contained, doesn't require docker, and runs on
macOS and all common flavors of Linux.

1. Install Trunk → `curl https://get.trunk.io -fsSL | bash`
2. Setup Trunk in your repo → `trunk init`
3. Check your changes for issues → `trunk check`
4. Format your changes → `trunk fmt`
5. Upgrade the pinned trunk version in your repo → `trunk upgrade`

Check out the [setup docs](https://docs.trunk.io/code-quality/setup-and-installation) for more info.

## Running Trunk Code Quality on all files

By default, `trunk check` will run on only changed files. When triggered by a pull request this will
be _all files changed in the PR_. When triggered by a push this will be _all files changed in that
push_. If you would like to run `trunk check` on all files in a repo, you can set the `check-mode`
to `all`. For example:

```yaml
- name: Trunk Code Quality
  uses: trunk-io/trunk-action@v1
  with:
    check-mode: all
```

If you're running an hourly or nightly job on a branch, `check-mode` is automatically inferred to be
`all`.

## Uploading results to the Trunk web app

[The Trunk web app](https://app.trunk.io/) can track results over time, give upgrade notifications
and suggestions, and more. For security, we never clone your repo in our backend. Instead, you set
up a periodic CI job to run `trunk check` on your repo, and it sends the results to Trunk.

By providing a `trunk-token` (as seen below) and running on a `schedule` workflow dispatch
([example](https://github.com/trunk-io/trunk-action/blob/main/.github/workflows/nightly.yaml)),
Trunk will infer to run with `check-mode` as `all` and to upload results to Trunk.

```yaml
- name: Trunk Code Quality
  uses: trunk-io/trunk-action@v1
  with:
    trunk-token: ${{ secrets.TRUNK_TOKEN }}
```

Note: When run as a periodic workflow on a branch, Trunk will automatically infer `check-mode` to be
`all`.

(See this repo's
[`nightly.yaml`](https://github.com/trunk-io/trunk-action/blob/main/.github/workflows/nightly.yaml)
workflow for further reference)

## Running Trunk Code Quality on multiple platforms

If you'd like to run multiple Trunk Code Quality jobs on different platforms at the same time, you
can pass `label` to each job to distinguish them. For example:

```yaml
- name: Trunk Code Quality
  uses: trunk-io/trunk-action@v1
  with:
    arguments: --github-label=${{ runner.os }}
```

## Annotating Existing Issues

By default, the Trunk Action will only annotate new issues, but if you also want to annotate
existing issues you can pass `--github-annotate-new-only=false` to Trunk Code Quality. For example:

```yaml
- name: Trunk Code Quality
  uses: trunk-io/trunk-action@v1
  with:
    arguments: --github-annotate-new-only=false
```

## Usage with the GitHub Merge Queue

Trunk auto-detects when it is running from the GitHub merge queue and will check only the files
being merged. The "Merge commit" and "Squash and merge"
[strategies](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue#about-merge-queues)
are currently supported. "Rebase and merge" does not yet work correctly.

## Automatic Upgrades

Once you have a `.trunk/trunk.yaml` checked into your repo, the following action will automatically
upgrade Trunk and its tools.

```yaml
name: Nightly
on:
  schedule:
    - cron: 0 8 * * 1-5
  workflow_dispatch: {}
permissions: read-all
jobs:
  trunk_upgrade:
    name: Upgrade Trunk
    runs-on: ubuntu-latest
    permissions:
      contents: write # For trunk to create PRs
      pull-requests: write # For trunk to create PRs
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      # >>> Install your own deps here (npm install, etc) <<<
      - name: Trunk Upgrade
        uses: trunk-io/trunk-action/upgrade@v1
```

We recommend that you only run the upgrade action on a nightly or weekly cadence, running from your
main branch. You can also set the `arguments` field to filter particular upgrades and set `base` to
define the branch to create a PR against (default `main`).

You must also enable the repository setting to "Allow GitHub Actions to create and approve pull
requests". If you have checks that run on pull requests, you will need to supply a `github-token` to
the upgrade action to run those checks. For more information, see
[create-pull-request](https://github.com/peter-evans/create-pull-request/blob/main/docs/concepts-guidelines.md#triggering-further-workflow-runs).

## Automatic trunk setup

To install trunk on your CI machine

```yaml
jobs:
  trunk_install:
    name: Install trunk
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      # >>> After this step, trunk is available as the env var TRUNK_PATH <<<
      - name: Trunk install
        uses: trunk-io/trunk-action/setup@v1
```

## Feedback

Join the [Trunk Community Slack][slack]. ❤️

[slack]: https://slack.trunk.io
[docs]: https://docs.trunk.io
[vscode]: https://marketplace.visualstudio.com/items?itemName=Trunk.io
