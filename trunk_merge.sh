#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
fi

fetch() {
  git -c protocol.version=2 fetch -q \
    --no-tags \
    --no-recurse-submodules \
    "$@"
}

head_sha=$(git rev-parse HEAD)
fetch --depth=2 origin "${head_sha}"
upstream=$(git rev-parse HEAD^1)
git_commit=$(git rev-parse HEAD^2)
echo "Detected merge queue commit, using HEAD^1 (${upstream}) as upstream and HEAD^2 (${git_commit}) as github commit"

"${TRUNK_PATH}" check \
  --ci \
  --upstream "${upstream}" \
  --github-commit "${git_commit}" \
  ${INPUT_ARGUMENTS}

if [[ -n ${INPUT_TRUNK_TOKEN} ]]; then
  "${TRUNK_PATH}" check \
    --ci \
    --upstream "${upstream}" \
    --github-commit "${git_commit}" \
    --github-label "${INPUT_LABEL}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    "${annotation_argument}" \
    ${INPUT_ARGUMENTS}
else
  "${TRUNK_PATH}" check \
    --ci \
    --upstream "${upstream}" \
    --github-commit "${git_commit}" \
    --github-label "${INPUT_LABEL}" \
    "${annotation_argument}" \
    ${INPUT_ARGUMENTS}
fi
