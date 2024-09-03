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

upstream=${GITHUB_EVENT_MERGE_GROUP_BASE_SHA}
git_commit=${GITHUB_EVENT_MERGE_GROUP_HEAD_SHA}
fetch origin "${upstream}"

"${TRUNK_PATH}" check \
  --ci \
  --upstream "${upstream}" \
  --github-commit "${git_commit}" \
  --github-label "${INPUT_LABEL}" \
  ${INPUT_ARGUMENTS}
