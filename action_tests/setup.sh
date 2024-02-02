#!/bin/bash

set -euo pipefail

src_repo=$1
output_repo=$2

git config --global init.defaultBranch main

## Set up repo in `src_repo`

mkdir -p "${src_repo}"
(
  cd "${src_repo}"

  git init

  git config user.name 'trunk-io/trunk-action action_tests'
  git config user.email 'action_tests@trunk-action.trunk.io'

  echo "This is a README." >>readme.md
  git add .
  git commit --all --message 'First commit'

  echo "These are contribution guidelines." >>contributing.md
  git add .
  git commit --all --message 'Second commit'

  ## Prepare a branch `feature-branch`

  git checkout -b feature-branch main^

  echo "markdown file for merge test" >>merge-test.md
  git add .
  git commit --all --message 'add file for merge test setup'

  ## Prepare a merge graph commit

  git checkout -b trunk-merge/of-feature-branch main

  git merge --no-ff --no-edit feature-branch

  ## Prepare a branch for payload pull_request

  git checkout feature-branch

  git checkout -b 1/merge main

  git merge --no-ff --no-edit feature-branch

  ## Go back to `main`

  git checkout main

  ## Dump the state of the repo

  git log --graph --pretty=oneline trunk-merge/of-feature-branch
  git log --graph --pretty=oneline 1/merge
)

## Set up repo in `output_repo`

git clone "${src_repo}" "${output_repo}"

## Force mktemp to point at TMPDIR

mkdir -p "${TMPDIR}"
