#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

fetch() {
  git -c protocol.version=2 fetch -q \
    --no-tags \
    --no-recurse-submodules \
    "$@"
}

head_sha=$(git rev-parse HEAD)
fetch --depth=2 origin "${head_sha}"
upstream=$(git rev-parse HEAD^1)
echo "Detected merge queue commit, using HEAD^1 (${upstream}) as upstream"

"${TRUNK_PATH}" check \
  --ci \
  --upstream "${upstream}" \
  --github-commit "${GITHUB_SHA}" \
  --github-label "${INPUT_LABEL}" \
  --github-annotate \
  ${INPUT_ARGUMENTS}
