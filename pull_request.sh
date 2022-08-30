#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

fetch() {
  git -c protocol.version=2 fetch -q \
    --no-tags \
    --no-recurse-submodules \
    "$@"
}

if [[ ${GITHUB_REF_NAME} == "${GITHUB_EVENT_PULL_REQUEST_NUMBER}/merge" ]]; then
  # If we have checked out the merge commit then fetch enough history to use HEAD^1 as the upstream.
  # We use this instead of github.event.pull_request.base.sha which can be incorrect sometimes.
  head_sha=$(git rev-parse HEAD)
  fetch --depth=2 origin "${head_sha}"
  upstream=$(git rev-parse HEAD^1)
  echo "Detected merge commit, using HEAD^1 (${upstream}) as upstream"
fi

if [[ -z ${upstream+x} ]]; then
  # Otherwise use github.event.pull_request.base.sha as the upstream.
  upstream="${GITHUB_EVENT_PULL_REQUEST_BASE_SHA}"
  fetch origin "${upstream}"
fi

"${TRUNK_PATH}" install \
  --ci

if [[ -n ${PRE_CHECK_COMMAND} ]]; then
  eval ${PRE_CHECK_COMMAND}
fi

"${TRUNK_PATH}" check \
  --ci \
  --upstream "${upstream}" \
  --github-commit "${GITHUB_EVENT_PULL_REQUEST_HEAD_SHA}" \
  --github-label "${INPUT_LABEL}" \
  --github-annotate \
  ${INPUT_ARGUMENTS}
