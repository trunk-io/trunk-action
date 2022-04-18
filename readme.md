<!-- trunk-ignore(markdownlint/MD041) -->
<p align="center">
  <a href="https://docs.trunk.io">
    <img height="128" src="https://static.trunk.io/assets/vscode_icon.png" />
  </a>
</p>
<h2 align="center">Trunk GitHub Action</h2>
<p align="center">
  <a href="https://marketplace.visualstudio.com/items?itemName=Trunk.io">
    <img src="https://img.shields.io/visual-studio-marketplace/i/Trunk.io?logo=visualstudiocode"/>
  </a>
  <a href="https://slack.trunk.io">
    <img src="https://img.shields.io/badge/slack-slack.trunk.io-blue?logo=slack"/>
  </a>
  <a href="https://docs.trunk.io">
    <img src="https://img.shields.io/badge/docs.trunk.io-7f7fcc?label=docs&logo=readthedocs&labelColor=555555&logoColor=ffffff"/>
  </a>
</p>

> 🎉 Trunk is in beta. We'd appreciate your feedback - stop by the
> [Trunk Community Slack](https://slack.trunk.io/) and let us know what you think. Thanks!

This action runs [`trunk check`](https://trunk.io), a super powerful meta linter and formatter,
showing inline annotations on your PRs for any issues found. Trunk runs just as well locally as on
CI, so you can always quickly see lint issues _before_ pushing your changes.

## Get Started

Before setting up running Trunk checking on CI, you'll need to initialize trunk in your repo.
Initializing it (`trunk init`) bootstraps a the trunk configuration (`.trunk/trunk.yaml`) which
stores all the configuration for Trunk. All linters and formatters, as well as the version of Trunk
itself, are versioned in `trunk.yaml`, so you're guarnateed to get the same results whether you're
running locally or on CI.

Check out the Trunk [CLI](https://docs.trunk.io/getting-started) and
[VS Code extension](https://marketplace.visualstudio.com/items?itemName=Trunk.io) to start using
Trunk locally.

1. Install Trunk → `curl https://get.trunk.io -fsSL | bash`
   ([docs](https://docs.trunk.io/getting-started))
2. Setup Trunk in your repo → `trunk init` ([docs](https://docs.trunk.io/getting-started))
3. Locally check your changes for issues → `trunk check` ([docs](https://docs.trunk.io/check))
4. Locally format your changes → `trunk fmt`
   ([docs](https://docs.trunk.io/using-trunk/cli-commands))
5. Make sure no lint and format issues leak onto `main` → **You're in the right place 👍**

## Usage

```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v2

  # >>> Install your own deps here (npm install, etc) <<<

  - name: Trunk Check
    uses: trunk-io/trunk-action@v1.0.1
```

(See this repo's
[`pr.yaml`](https://github.com/trunk-io/trunk-action/blob/main/.github/workflows/pr.yaml) workflow
for further reference)

### Installing your own deps

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

By default, Trunk will cache linters/formatters via `actions/cache@v2`. This is great if you are
using GitHub-hosted ephemeral runners.

If you are using long-lived self-hosted runners you should disable caching by passing `cache: false`
as so:

```yaml
- name: Trunk Check
  uses: trunk-io/trunk-action@v1.0.1
  with:
    cache: false
```

Note: Previous versions of the Trunk GitHub Action did _not_ include caching and instead we
recommended users use `actions/cache@v2`. If you were previously using `actions/cache@v2` to cache
Trunk, please remove it from your workflow.

## Linters

We integrate new linters every release. Stop by on [slack](https://slack.trunk.io/) and let us know
what you'd like next!

We currently support the following linters.

| Language        | Linters                                                                          |
| --------------- | -------------------------------------------------------------------------------- |
| All             | `gitleaks`                                                                       |
| Ansible         | `ansible-lint`                                                                   |
| Bash            | `shellcheck`, `shfmt`                                                            |
| Bazel, Starlark | `buildifier`                                                                     |
| C/C++           | `clang-format`, `clang-tidy`                                                     |
| Cloudformation  | `cfnlint`                                                                        |
| Docker          | `hadolint`                                                                       |
| GitHub          | `actionlint`                                                                     |
| Go              | `gofmt`, `golangci-lint`, `semgrep`                                              |
| Java            | `semgrep`                                                                        |
| JS/TS           | `eslint`, `prettier`, `semgrep`                                                  |
| Kotlin          | `detekt`, `detekt-explicit`, `ktlint`                                            |
| Markdown        | `markdownlint`                                                                   |
| Protobuf        | `buf-breaking`, `buf-lint`                                                       |
| Python          | `autopep8`, `bandit`, `black-py`, `flake8`, `isort`, `pylint`, `semgrep`, `yapf` |
| Ruby            | `brakeman`, `rubocop`, `rufo`, `semgrep`                                         |
| Rust            | `clippy`, `rustfmt`                                                              |
| Terraform       | `terraform-fmt`, `terraform-validate`, `tflint`                                  |
| TOML            | `taplo`                                                                          |

## Trunk versioning

After you `trunk init`, `trunk.yaml` will contain a pinned version of Trunk to use for your repo.
When you run trunk, it will automatically detect which version you should be running for a
particular repo and download+run it. This means that everyone working in a repo, and CI, all get the
same results and the same experience. no more "doesn't happen on my machine". When you want to
upgrade to a newer verison, just run `trunk upgrade` and commit the updated `trunk.yaml`.

## Run Trunk outside of GitHub Actions

Trunk has a dead simple install, is totally self-contained, doesn't require docker, and runs on
macOS and all common flavors of Linux.

1. Install Trunk → `curl https://get.trunk.io -fsSL | bash`
   ([docs](https://docs.trunk.io/getting-started))
2. Setup Trunk in your repo → `trunk init` ([docs](https://docs.trunk.io/getting-started))
3. Check your changes for issues → `trunk check` ([docs](https://docs.trunk.io/check))
4. Format your changes → `trunk fmt` ([docs](https://docs.trunk.io/using-trunk/cli-commands))
5. Upgrade the pinned trunk version in your repo → `trunk upgrade`
   ([docs](https://docs.trunk.io/using-trunk/cli-commands))

Check out our [Getting Started guide](https://docs.trunk.io/getting-started) for more info.

## Running trunk check on all files

By default trunk check will run on only changed files. When triggered by a pull request this will be
all files changed in the PR. When triggered by a push this will be all files changed in that push.
If you would like to run trunk check on all files in a repo, you can set the check-mode to `all`.
For example:

```yaml
- name: Trunk Check
  uses: trunk-io/trunk-action@v1.0.1
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
  uses: trunk-io/trunk-action@v1.0.1
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
  uses: trunk-io/trunk-action@v1.0.1
  with:
    arguments: --github-label=${{ runner.os }}
```

## Annotating existing issues

By default the Trunk Action will only annotate new issues, but if you also want to annotate existing
issues you can pass `--github-annotate-new-only=false` to Trunk Check. For example:

```yaml
- name: Trunk Check
  uses: trunk-io/trunk-action@v1.0.1
  with:
    arguments: --github-annotate-new-only=false
```

## Usage with the github merge queue

Trunk auto-detects when it is running from the github merge queue and will check only the files
being merged. The `merge` and `squash` strategies are currently supported. `rebase` does not yet
work correctly.

## Feedback

Join the [Trunk Community Slack](https://slack.trunk.io/). ❤️
