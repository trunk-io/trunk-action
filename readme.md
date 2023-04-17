<!-- markdownlint-disable first-line-heading -->

[![Trunk.io](https://user-images.githubusercontent.com/3904462/199616921-7861e331-c774-43bf-8c17-1ecd27d0a750.png)](https://trunk.io)

[![docs](https://img.shields.io/badge/-docs-darkgreen?logo=readthedocs&logoColor=ffffff)][docs]
[![vscode](https://img.shields.io/visual-studio-marketplace/i/trunk.io?color=0078d7&label=vscode&logo=visualstudiocode)][vscode]
[![slack](https://img.shields.io/badge/-slack-611f69?logo=slack)][slack]
[![openssf](https://api.securityscorecards.dev/projects/github.com/trunk-io/trunk-action/badge)](https://api.securityscorecards.dev/projects/github.com/trunk-io/trunk-action)

# Trunk.io GitHub Action

This action runs and shows inline annotations of issues found by
[`trunk check`](https://docs.trunk.io/docs/check), a powerful meta linter and formatter. Trunk runs
hermetically, _locally_ or on CI, so you can always quickly see lint, formatting, and security
issues _before_ pushing your changes. See all supported linters
[here](https://github.com/trunk-io/plugins).

<p align="center">
  <img src="https://user-images.githubusercontent.com/46629651/232631742-645be266-5ea1-4a97-aa6d-6da868c056a8.png" height="300"/>
  <br>
  <em>Example annotations</em>
</p>
  
## Get Started

Before setting up running Trunk Check on CI, you'll need to initialize trunk in your repo.
Initializing it (`trunk init`) bootstraps the trunk configuration (`.trunk/trunk.yaml`) which stores
all the configurations for Trunk. All linters and formatters, as well as the version of Trunk
itself, are versioned in `trunk.yaml`, so you're guaranteed to get the same results whether you're
running locally or on CI.

Check out the Trunk [CLI](https://docs.trunk.io/docs/overview) and [VS Code extension][vscode] to
start using Trunk locally.

1. Install Trunk → `curl https://get.trunk.io -fsSL | bash`
2. Setup Trunk in your repo → `trunk init`
3. Locally check your changes for issues → `trunk check`
4. Locally format your changes → `trunk fmt`
5. Make sure no lint and format issues leak onto `main` → **You're in the right place 👍**

## Usage

```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v3

  # >>> Install your own deps here (npm install, etc) <<<

  - name: Trunk Check
    uses: trunk-io/trunk-action@v1
```

(See this repo's
[`pr.yaml`](https://github.com/trunk-io/trunk-action/blob/main/.github/workflows/pr.yaml) workflow
for further reference)

### Installing your own dependencies

You do need to install your own dependencies (`npm install`, etc) as a step in your workflow before
the `trunk-io/trunk-action` step. Many linters will follow imports/includes in your code to find
errors in your usage and thus they need you to have your dependencies installed and available.

If you've setup basic testing on CI, you're already doing this for other CI jobs; Do it here too 😉.
Here's some GitHub docs to get you going:
[[nodejs](https://docs.github.com/en/actions/guides/building-and-testing-nodejs),
[ruby](https://docs.github.com/en/actions/guides/building-and-testing-ruby),
[python](https://docs.github.com/en/actions/guides/building-and-testing-python),
[many more](https://docs.github.com/en/actions/guides/about-continuous-integration)]

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
should also disable caching by passing `cache: false` as so when running Trunk on your PRs:

```yaml
- name: Trunk Check
  uses: trunk-io/trunk-action@v3
  with:
    cache: false
```

### Getting inline annotations for fork PRs

Create an additional _new GitHub workflow_ to post annotations from fork PRs. This workflow needs to
be merged into your main branch before fork PRs will see annotations. It's important that the name
of the workflow in the workflow_runs section (here "Pull Request") matches the workflow which runs
trunk check:

```yaml
name: Annotate PR with trunk issues

on:
  workflow_run:
    workflows: ["Pull Request"]
    types: [completed]

jobs:
  trunk_check:
    name: Trunk Check Annotate
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
trying to post them. Creating the new github workflow above downloads this artifact and posts the
annotations.

This also works if you use both fork and non-fork PRs in your repo. In that case, non-fork PRs post
annotations in the regular manner, and fork PRs post annotations via the above workflow.

## Trunk versioning

After you `trunk init`, `.trunk/trunk.yaml` will contain a pinned version of Trunk to use for your
repo. When you run trunk, it will automatically detect which version you should be running for a
particular repo and download+run it. This means that everyone working in a repo, and CI, all get the
same results and the same experience - no more "doesn't happen on my machine". When you want to
upgrade to a newer verison, just run `trunk upgrade` and commit the updated `trunk.yaml`.

## Run Trunk outside of GitHub Actions

Trunk has a dead simple install, is totally self-contained, doesn't require docker, and runs on
macOS and all common flavors of Linux.

1. Install Trunk → `curl https://get.trunk.io -fsSL | bash`
2. Setup Trunk in your repo → `trunk init`
3. Check your changes for issues → `trunk check`
4. Format your changes → `trunk fmt`
5. Upgrade the pinned trunk version in your repo → `trunk upgrade`

Check out our [docs](https://docs.trunk.io) for more info.

## Running trunk check on all files

By default trunk check will run on only changed files. When triggered by a pull request this will be
all files changed in the PR. When triggered by a push this will be all files changed in that push.
If you would like to run trunk check on all files in a repo, you can set the check-mode to `all`.
For example:

```yaml
- name: Trunk Check
  uses: trunk-io/trunk-action@v1
  with:
    check-mode: all
```

If you're running an hourly or nightly job on a branch, `check-mode` is automatically inferred to be
`all`.

## Uploading results to the Trunk web app

[The Trunk web app](https://app.trunk.io/) can track results over time, give upgrade notifications
and suggestions, and more. For security, we never clone your repo in our backend. Instead, you set
up a periodic CI job to run `trunk check` on your repo and it sends the results to Trunk.

By providing a `trunk-token` (as seen below) and running on a `schedule` workflow dispatch
([example](https://github.com/trunk-io/trunk-action/blob/main/.github/workflows/nightly.yaml)),
Trunk will infer to run with `check-mode` as `all` and to upload results to Trunk.

```yaml
- name: Trunk Check
  uses: trunk-io/trunk-action@v1
  with:
    trunk-token: ${{ secrets.TRUNK_TOKEN }}
```

Note: When run as a periodic workflow on a branch, Trunk will automatically infer `check-mode` to be
`all`.

(See this repo's
[`nightly.yaml`](https://github.com/trunk-io/trunk-action/blob/main/.github/workflows/nightly.yaml)
workflow for further reference)

## Running trunk check on multiple platforms

If you'd like to run multiple Trunk Check jobs on different platforms at the same time, you can pass
`label` to each job to distinguish them. For example:

```yaml
- name: Trunk Check
  uses: trunk-io/trunk-action@v1
  with:
    arguments: --github-label=${{ runner.os }}
```

## Annotating existing issues

By default the Trunk Action will only annotate new issues, but if you also want to annotate existing
issues you can pass `--github-annotate-new-only=false` to Trunk Check. For example:

```yaml
- name: Trunk Check
  uses: trunk-io/trunk-action@v1
  with:
    arguments: --github-annotate-new-only=false
```

## Usage with the github merge queue

Trunk auto-detects when it is running from the github merge queue and will check only the files
being merged. The "Merge commit" and "Squash and merge"
[strategies](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue#about-merge-queues)
are currently supported. "Rebase and merge" does not yet work correctly.

## Feedback

Join the [Trunk Community Slack][slack]. ❤️

[slack]: https://slack.trunk.io
[docs]: https://docs.trunk.io
[vscode]: https://marketplace.visualstudio.com/items?itemName=Trunk.io
