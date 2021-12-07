#!/bin/bash

set -euo pipefail

fetch() {
  git -c protocol.version=2 fetch -q \
    --no-tags \
    --prune \
    --no-recurse-submodules \
    "$@"
}

# If we have checked out the merge commit then fetch enough history to use HEAD^1 as the upstream.
# This is more reliable than github.event.pull_request.base.sha.
merge_commit_ref=refs/remotes/pull/${GITHUB_EVENT_PULL_REQUEST_NUMBER}/merge
if git rev-parse --verify -q "${merge_commit_ref}" >/dev/null; then
  head_sha=$(git rev-parse HEAD)
  merge_commit_sha=$(git rev-parse "${merge_commit_ref}")
  if [[ ${merge_commit_sha} == "${head_sha}" ]]; then
    fetch --depth=2 origin "+${head_sha}:${merge_commit_ref}"
    upstream=$(git rev-parse HEAD^1)
    echo "Detected merge commit, using HEAD^1 (${upstream}) as upstream"
  fi
fi

# Otherwise use github.event.pull_request.base.sha as the upstream.
if [[ -z ${upstream+x} ]]; then
  upstream="${GITHUB_EVENT_PULL_REQUEST_BASE_SHA}"
  fetch origin "${upstream}"
fi

# shellcheck disable=SC2086
"${TRUNK_PATH}" check \
  --ci \
  --upstream "${upstream}" \
  --github-commit "${GITHUB_EVENT_PULL_REQUEST_HEAD_SHA}" \
  --github-label "${INPUTS_LABEL}" \
  --github-annotate \
  ${INPUTS_ARGUMENTS}
