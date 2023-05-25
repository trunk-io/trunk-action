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

if [[ ${TRUNK_CHECK_MODE} == "all" ]]; then
  if [[ -n ${INPUT_TRUNK_TOKEN} && ${INPUT_CHECK_ALL_MODE} == "hold-the-line" ]]; then
    latest_raw_upload="$(mktemp)"
    prev_ref="$("${TRUNK_PATH}" check get-latest-raw-output \
      --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
      --token "${INPUT_TRUNK_TOKEN}" \
      "${latest_raw_upload}")"
    if ! [[ ${prev_ref} =~ .*UNSPECIFIED.* ]]; then
      git fetch origin "${prev_ref}"
    fi
  fi
elif [[ ${TRUNK_CHECK_MODE} == "pull_request" ]]; then
  if [[ ${INPUT_GITHUB_REF_NAME} == "${GITHUB_EVENT_PULL_REQUEST_NUMBER}/merge" ]]; then
    # If we have checked out the merge commit then fetch enough history to use HEAD^1 as the upstream.
    # We use this instead of github.event.pull_request.base.sha which can be incorrect sometimes.
    head_sha=$(git rev-parse HEAD)
    fetch --depth=2 origin "${head_sha}"
    upstream=$(git rev-parse HEAD^1)
    git_commit=$(git rev-parse HEAD^2)
    echo "Detected merge commit, using HEAD^1 (${upstream}) as upstream and HEAD^2 (${git_commit}) as github commit"
  fi

  if [[ -z ${upstream+x} ]]; then
    # Otherwise use github.event.pull_request.base.sha as the upstream.
    upstream="${GITHUB_EVENT_PULL_REQUEST_BASE_SHA}"
    git_commit="${GITHUB_EVENT_PULL_REQUEST_HEAD_SHA}"
    fetch origin "${upstream}"
  fi
elif [[ ${TRUNK_CHECK_MODE} == "push" ]]; then
  if [[ ${GITHUB_REF_NAME} == gh-readonly-queue/* ]]; then
    # If we are running via the GH merge queue then we use HEAD^1 as the commit as github.event.before will be inaccurate.
    head_sha=$(git rev-parse HEAD)
    fetch --depth=2 origin "${head_sha}"
    upstream=$(git rev-parse HEAD^1)
    echo "Detected merge queue commit, using HEAD^1 (${upstream}) as upstream"
  fi

  if [[ -z ${upstream+x} ]]; then
    # Otherwise use github.event.before as the upstream.
    upstream="${GITHUB_EVENT_BEFORE}"
    fetch origin "${upstream}"
  fi
elif [[ ${TRUNK_CHECK_MODE} == "trunk_merge" ]]; then
  head_sha=$(git rev-parse HEAD)
  fetch --depth=2 origin "${head_sha}"
  upstream=$(git rev-parse HEAD^1)
  git_commit=$(git rev-parse HEAD^2)
  echo "Detected merge queue commit, using HEAD^1 (${upstream}) as upstream and HEAD^2 (${git_commit}) as github commit"
fi
