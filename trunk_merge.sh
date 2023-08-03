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

MINIMUM_CHECK_RUN_ID_VERSION=1.7.0

head_sha=$(git rev-parse HEAD)
fetch --depth=2 origin "${head_sha}"
upstream=$(git rev-parse HEAD^1)
git_commit=$(git rev-parse HEAD^2)
echo "Detected merge queue commit, using HEAD^1 (${upstream}) as upstream and HEAD^2 (${git_commit}) as github commit"

if [[ -n ${INPUT_CHECK_RUN_ID} ]]; then
  trunk_version="$(${TRUNK_PATH} version)"
  # trunk-ignore-begin(shellcheck/SC2312): the == will fail if anything inside the $() fails
  if [[ "$(printf "%s\n%s\n" "${MINIMUM_CHECK_RUN_ID_VERSION}" "${trunk_version}" |
    sort --version-sort |
    head -n 1)" == "${trunk_version}"* ]]; then
    echo "::error::Please update your CLI to ${MINIMUM_CHECK_RUN_ID_VERSION} or higher (current version ${trunk_version})."
    exit 1
  fi
  # trunk-ignore-end(shellcheck/SC2312)
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
