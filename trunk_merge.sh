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

if [[ -z ${TEST_GITHUB_EVENT_PATH+x} ]]; then
  head_sha=$(git rev-parse HEAD)
  fetch --depth=2 origin "${head_sha}"
  upstream=$(git rev-parse HEAD^1)
  git_commit=$(git rev-parse HEAD^2)
  echo "Detected merge queue commit, using HEAD^1 (${upstream}) as upstream and HEAD^2 (${git_commit}) as github commit"
else
  upstream="${EXPECTED_UPSTREAM}"
  git_commit="${EXPECTED_GITHUB_COMMIT}"
fi

if [[ -n ${INPUT_CHECK_RUN_ID} ]]; then
  annotation_argument=--trunk-annotate=${INPUT_CHECK_RUN_ID}
else
  annotation_argument=""
fi

"${TRUNK_PATH}" check \
  --ci \
  --upstream "${upstream}" \
  --github-commit "${git_commit}" \
  --github-label "${INPUT_LABEL}" \
  ${annotation_argument} \
  ${INPUT_ARGUMENTS}
